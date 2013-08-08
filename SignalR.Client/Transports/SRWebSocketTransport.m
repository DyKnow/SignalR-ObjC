//
//  SRWebSocketTransport.m
//  SignalR
//
//  Created by Alex Billingsley on 4/8/13.
//  Copyright (c) 2011 DyKnow LLC. (http://dyknow.com/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
//  documentation files (the "Software"), to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and
//  to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of
//  the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
//  THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
//  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
//

#import "AFHTTPRequestOperation.h"
#import "SRWebSocketTransport.h"
#import "SRWebSocket.h"
#import "SRLog.h"
#import "SRWebSocketConnectionInfo.h"
#import "SRConnectionInterface.h"
#import "SRConnectionExtensions.h"

typedef void (^SRWebSocketStartBlock)(id response);

@interface SRWebSocketTransport () <SRWebSocketDelegate>

@property (strong, nonatomic, readonly) SRWebSocket *webSocket;
@property (strong, nonatomic, readonly) SRWebSocketConnectionInfo *connectionInfo;
@property (copy) SRWebSocketStartBlock startBlock;

@end

@implementation SRWebSocketTransport

- (instancetype)init {
    if (self = [super init]) {
        _reconnectDelay = @2;
    }
    return self;
}

#pragma mark
#pragma mark SRClientTransportInterface

- (NSString *)name {
    return @"webSockets";
}

- (BOOL)supportsKeepAlive {
    return YES;
}

- (void)negotiate:(id <SRConnectionInterface>)connection completionHandler:(void (^)(SRNegotiationResponse *response))block {
    [super negotiate:connection completionHandler:block];
}

- (void)start:(id <SRConnectionInterface>)connection data:(NSString *)data completionHandler:(void (^)(id response))block {
    _connectionInfo = [[SRWebSocketConnectionInfo alloc] initConnection:connection data:data];
    [self performConnect:block];
}

- (void)performConnect:(void (^)(id response))block {
    [self performConnect:block reconnecting:NO];
}

- (void)performConnect:(void (^)(id response))block reconnecting:(BOOL)reconnecting {
    NSString *urlString = [_connectionInfo.connection.url stringByAppendingString:reconnecting ? @"reconnect" : @"connect"];
    urlString = [urlString stringByAppendingString:[self receiveQueryString:_connectionInfo.connection data:_connectionInfo.data]];
        
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    
    [_connectionInfo.connection prepareRequest:urlRequest];
    
    SRLogWebSocket(@"WS: %@",[urlRequest.URL absoluteString]);
    
    [self setStartBlock:block];
    
    _webSocket = [[SRWebSocket alloc] initWithURLRequest:urlRequest];
    [_webSocket setDelegate:self];
    [_webSocket open];
}

- (void)send:(id <SRConnectionInterface>)connection data:(NSString *)data completionHandler:(void (^)(id response))block {
    [_webSocket send:data];
    
    if(block) {
        block(nil);
    }
}

- (void)lostConnection:(id<SRConnectionInterface>)connection {
    [_webSocket close];
    [_webSocket setDelegate:nil];
    _webSocket = nil;
}

- (void)abort:(id <SRConnectionInterface>)connection timeout:(NSNumber *)timeout {
    [_webSocket close];
    [_webSocket setDelegate:nil];
    _webSocket = nil;
}

#pragma mark -
#pragma mark SRWebSocketDelegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    SRLogWebSocket(@"Websocket Connected");
    
    if (self.startBlock) {
        self.startBlock(nil);
    } else if ([[_connectionInfo connection] changeState:reconnecting toState:connected]) {
        [[_connectionInfo connection] didReconnect];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    SRLogWebSocket(@"WS Receive: %@", message);
    
    BOOL timedOut = NO;
    BOOL disconnected = NO;
    
    [self processResponse:_connectionInfo.connection response:message timedOut:&timedOut disconnected:&disconnected];
    
    if (disconnected) {
        [[_connectionInfo connection] disconnect];
        [_webSocket close];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    SRLogWebSocket(@"Websocket Failed With Error %@, %@", [[_connectionInfo connection] connectionId], error);
    
    [[_connectionInfo connection] didReceiveError:error];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    SRLogWebSocket(@"WebSocket closed");
}

@end
