//
//  SRWebSocket.m
//  SignalR
//
//  Created by Alex Billingsley on 10/24/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "SRWebSocket.h"
#import "GCDAsyncSocket.h"

NSString* const SRWebSocketErrorDomain = @"SRWebSocketErrorDomain";
NSString* const SRWebSocketException = @"SRWebSocketException";

enum {
    SRWebSocketTagHandshake = 0,
    SRWebSocketTagMessage = 1
};

@implementation SRWebSocket

@synthesize delegate = _delegate;

@synthesize connected = _connected;
@synthesize url = _url;
@synthesize origin = _origin;
@synthesize socket = _socket;

#pragma mark Initializers

+ (id)webSocketWithURLString:(NSString*)urlString delegate:(id<SRWebSocketDelegate>)aDelegate {
    return [[SRWebSocket alloc] initWithURLString:urlString delegate:aDelegate];
}

-(id)initWithURLString:(NSString *)urlString delegate:(id<SRWebSocketDelegate>)aDelegate {
    if (self=[super init]) {
        self.delegate = aDelegate;
        _url = [NSURL URLWithString:urlString];
        if (![_url.scheme isEqualToString:@"ws"]) {
            [NSException raise:SRWebSocketException format:[NSString stringWithFormat:@"Unsupported protocol %@",_url.scheme]];
        }

        /*NSError *error = nil;
		if (![_socket connectToHost:@"www.paypal.com" onPort:port error:&error])
		{
			NSLog(@"Error connecting: %@", error);
		}*/
    }
    return self;
}

#pragma mark Delegate dispatch methods

-(void)_dispatchFailure:(NSNumber*)code {
    if(_delegate && [_delegate respondsToSelector:@selector(webSocket:didFailWithError:)]) {
        [_delegate webSocket:self didFailWithError:[NSError errorWithDomain:SRWebSocketErrorDomain code:[code intValue] userInfo:nil]];
    }
}

-(void)_dispatchClosed {
    if (_delegate && [_delegate respondsToSelector:@selector(webSocketDidClose:)]) {
        [_delegate webSocketDidClose:self];
    }
}

-(void)_dispatchOpened {
    if (_delegate && [_delegate respondsToSelector:@selector(webSocketDidOpen:)]) {
        [_delegate webSocketDidOpen:self];
    }
}

-(void)_dispatchMessageReceived:(NSString*)message {
    if (_delegate && [_delegate respondsToSelector:@selector(webSocket:didReceiveMessage:)]) {
        [_delegate webSocket:self didReceiveMessage:message];
    }
}

-(void)_dispatchMessageSent {
    if (_delegate && [_delegate respondsToSelector:@selector(webSocketDidSendMessage:)]) {
        [_delegate webSocketDidSendMessage:self];
    }
}

#pragma mark Private

-(void)_readNextMessage {
    //[_socket readDataToData:[NSData dataWithBytes:"\xFF" length:1] withTimeout:-1 tag:SRWebSocketTagMessage];
}

#pragma mark Public interface
/*
-(void)open {
    if (!self.isConnected) {
        [_socket connectToHost:_url.host onPort:[_url.port intValue] withTimeout:5 error:nil];
        if (runLoopModes) [_socket setRunLoopModes:runLoopModes];
    }
}

-(void)send:(NSString*)message {
    NSMutableData* data = [NSMutableData data];
    [data appendBytes:"\x00" length:1];
    [data appendData:[message dataUsingEncoding:NSUTF8StringEncoding]];
    [data appendBytes:"\xFF" length:1];
    [self.socket writeData:data withTimeout:-1 tag:SRWebSocketTagMessage];
}

-(void)close {
    [socket disconnectAfterReadingAndWriting];
}*/

#pragma mark AsyncSocket delegate methods

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{  
#if DEBUG
    NSLog(@"socket:%p didConnectToHost:%@ port:%hu", sock, host, port);
#endif
    
    NSString* requestOrigin = self.origin;
    if (!requestOrigin) requestOrigin = [NSString stringWithFormat:@"http://%@:%d",_url.host,port];
    
    NSString *requestPath = _url.path;
    if (_url.query) requestPath = [requestPath stringByAppendingFormat:@"?%@", _url.query];
    if([requestPath isEqualToString:@""]) requestPath = @"/";
    
    NSString* getRequest = [NSString stringWithFormat:@""
                            "GET %@ HTTP/1.1\r\n"
                            "Upgrade: websocket\r\n"
                            "Connection: Upgrade\r\n"
                            "Host: %@\r\n"
                            "Origin: %@\r\n"
                            "\r\n",
                            requestPath,_url.host,requestOrigin];
    
    [sock writeData:[getRequest dataUsingEncoding:NSASCIIStringEncoding] withTimeout:-1 tag:SRWebSocketTagHandshake];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
#if DEBUG
	NSLog(@"socket:%p didWriteDataWithTag:%ld", sock, tag);
#endif
    if (tag == SRWebSocketTagHandshake) {
        [sock readDataToData:[@"\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding] withTimeout:-1 tag:SRWebSocketTagHandshake];
    } else if (tag == SRWebSocketTagMessage) {
        [self _dispatchMessageSent];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
#if DEBUG
	NSLog(@"socket:%p didReadData:withTag:%ld", sock, tag);
#endif
    if (tag == SRWebSocketTagHandshake) {
        NSString *response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
#if DEBUG
        NSLog(@"HTTP Response:\n%@", response);
#endif
        if ([response hasPrefix:@"HTTP/1.1 101 Web Socket Protocol Handshake\r\nUpgrade: WebSocket\r\nConnection: Upgrade\r\n"]) {
            _connected = YES;
            [self _dispatchOpened];
            
            [self _readNextMessage];
        } else {
            [self _dispatchFailure:[NSNumber numberWithInt:SRWebSocketErrorHandshakeFailed]];
        }
    } else if (tag == SRWebSocketTagMessage) {
        char firstByte = 0xFF;
        [data getBytes:&firstByte length:1];
        if (firstByte != 0x00) return; // Discard message
        NSString* message = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(1, [data length]-2)] encoding:NSUTF8StringEncoding];
        
        [self _dispatchMessageReceived:message];
        [self _readNextMessage];
    }
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
	NSLog(@"socketDidDisconnect:%p withError: %@", sock, err);
}

@end
