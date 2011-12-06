//
//  SRWebSocket.m
//  SignalR
//
//  Created by Alex Billingsley on 10/24/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "SRWebSocket.h"
#import "AsyncSocket.h"

NSString* const SRWebSocketErrorDomain = @"SRWebSocketErrorDomain";
NSString* const SRWebSocketException = @"SRWebSocketException";

enum {
    SRWebSocketTagHandshake = 0,
    SRWebSocketTagMessage = 1
};

@implementation SRWebSocket

@synthesize delegate, url, origin, connected, runLoopModes;

#pragma mark Initializers

+ (id)webSocketWithURLString:(NSString*)urlString delegate:(id<SRWebSocketDelegate>)aDelegate {
    return [[[SRWebSocket alloc] initWithURLString:urlString delegate:aDelegate] autorelease];
}

-(id)initWithURLString:(NSString *)urlString delegate:(id<SRWebSocketDelegate>)aDelegate {
    if (self=[super init]) {
        self.delegate = aDelegate;
        url = [[NSURL URLWithString:urlString] retain];
        if (![url.scheme isEqualToString:@"ws"]) {
            [NSException raise:SRWebSocketException format:[NSString stringWithFormat:@"Unsupported protocol %@",url.scheme]];
        }
        socket = [[AsyncSocket alloc] initWithDelegate:self];
        self.runLoopModes = [NSArray arrayWithObjects:NSRunLoopCommonModes, nil]; 
    }
    return self;
}

#pragma mark Delegate dispatch methods

-(void)_dispatchFailure:(NSNumber*)code {
    if(delegate && [delegate respondsToSelector:@selector(webSocket:didFailWithError:)]) {
        [delegate webSocket:self didFailWithError:[NSError errorWithDomain:SRWebSocketErrorDomain code:[code intValue] userInfo:nil]];
    }
}

-(void)_dispatchClosed {
    if (delegate && [delegate respondsToSelector:@selector(webSocketDidClose:)]) {
        [delegate webSocketDidClose:self];
    }
}

-(void)_dispatchOpened {
    if (delegate && [delegate respondsToSelector:@selector(webSocketDidOpen:)]) {
        [delegate webSocketDidOpen:self];
    }
}

-(void)_dispatchMessageReceived:(NSString*)message {
    if (delegate && [delegate respondsToSelector:@selector(webSocket:didReceiveMessage:)]) {
        [delegate webSocket:self didReceiveMessage:message];
    }
}

-(void)_dispatchMessageSent {
    if (delegate && [delegate respondsToSelector:@selector(webSocketDidSendMessage:)]) {
        [delegate webSocketDidSendMessage:self];
    }
}

#pragma mark Private

-(void)_readNextMessage {
    [socket readDataToData:[NSData dataWithBytes:"\xFF" length:1] withTimeout:-1 tag:SRWebSocketTagMessage];
}

#pragma mark Public interface

-(void)open {
    if (!connected) {
        [socket connectToHost:url.host onPort:[url.port intValue] withTimeout:5 error:nil];
        if (runLoopModes) [socket setRunLoopModes:runLoopModes];
    }
}

-(void)send:(NSString*)message {
    NSMutableData* data = [NSMutableData data];
    [data appendBytes:"\x00" length:1];
    [data appendData:[message dataUsingEncoding:NSUTF8StringEncoding]];
    [data appendBytes:"\xFF" length:1];
    [socket writeData:data withTimeout:-1 tag:SRWebSocketTagMessage];
}

-(void)close {
    [socket disconnectAfterReadingAndWriting];
}

#pragma mark AsyncSocket delegate methods

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
    
    NSString* requestOrigin = self.origin;
    if (!requestOrigin) requestOrigin = [NSString stringWithFormat:@"http://%@:%d",url.host,port];
    
    NSString *requestPath = url.path;
    if (url.query) requestPath = [requestPath stringByAppendingFormat:@"?%@", url.query];
    if([requestPath isEqualToString:@""]) requestPath = @"/";
    
    NSString* getRequest = [NSString stringWithFormat:@""
                            "GET %@ HTTP/1.1\r\n"
                            "Upgrade: websocket\r\n"
                            "Connection: Upgrade\r\n"
                            "Host: %@\r\n"
                            "Origin: %@\r\n"
                            "\r\n",
                            requestPath,url.host,requestOrigin];
#if DEBUG
    NSLog(@"%@",getRequest);
#endif
    [socket writeData:[getRequest dataUsingEncoding:NSASCIIStringEncoding] withTimeout:-1 tag:SRWebSocketTagHandshake];
}

-(void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag {
    if (tag == SRWebSocketTagHandshake) {
        [sock readDataToData:[@"\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding] withTimeout:-1 tag:SRWebSocketTagHandshake];
    } else if (tag == SRWebSocketTagMessage) {
        [self _dispatchMessageSent];
    }
}

-(void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if (tag == SRWebSocketTagHandshake) {
        NSString* response = [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
#if DEBUG
        NSLog(@"%@",response);
#endif
        if ([response hasPrefix:@"HTTP/1.1 101 Web Socket Protocol Handshake\r\nUpgrade: WebSocket\r\nConnection: Upgrade\r\n"]) {
            connected = YES;
            [self _dispatchOpened];
            
            [self _readNextMessage];
        } else {
            [self _dispatchFailure:[NSNumber numberWithInt:SRWebSocketErrorHandshakeFailed]];
        }
    } else if (tag == SRWebSocketTagMessage) {
        char firstByte = 0xFF;
        [data getBytes:&firstByte length:1];
        if (firstByte != 0x00) return; // Discard message
        NSString* message = [[[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(1, [data length]-2)] encoding:NSUTF8StringEncoding] autorelease];
        
        [self _dispatchMessageReceived:message];
        [self _readNextMessage];
    }
}

-(void)onSocketDidDisconnect:(AsyncSocket *)sock {
    connected = NO;
}

-(void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err {
    if (!connected) {
        [self _dispatchFailure:[NSNumber numberWithInt:SRWebSocketErrorConnectionFailed]];
    } else {
        [self _dispatchClosed];
    }
}


#pragma mark Destructor

-(void)dealloc {
    socket.delegate = nil;
    [socket disconnect];
    [socket release];
    [runLoopModes release];
    [url release];
    [super dealloc];
}


@end
