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

#import <AFNetworking/AFNetworking.h>
#import <SocketRocket/SRWebSocket.h>
#import "SRWebSocketTransport.h"
#import "SRLog.h"
#import "SRWebSocketConnectionInfo.h"
#import "SRConnectionInterface.h"
#import "SRConnectionExtensions.h"

typedef void (^SRWebSocketStartBlock)(id response, NSError *error);

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

- (void)negotiate:(id<SRConnectionInterface>)connection connectionData:(NSString *)connectionData completionHandler:(void (^)(SRNegotiationResponse *response, NSError *error))block {
    [super negotiate:connection connectionData:connectionData completionHandler:block];
}

- (void)start:(id<SRConnectionInterface>)connection connectionData:(NSString *)connectionData completionHandler:(void (^)(id response, NSError *error))block {
    _connectionInfo = [[SRWebSocketConnectionInfo alloc] initConnection:connection data:connectionData];
    [self performConnect:block];
}

- (void)send:(id<SRConnectionInterface>)connection data:(NSString *)data connectionData:(NSString *)connectionData completionHandler:(void (^)(id response, NSError *error))block {
    [_webSocket send:data];
    
    if(block) {
        block(nil,nil);
    }
}

- (void)abort:(id <SRConnectionInterface>)connection timeout:(NSNumber *)timeout connectionData:(NSString *)connectionData {
    [_webSocket setDelegate:nil];
    [_webSocket close];
    _webSocket = nil;
}

- (void)lostConnection:(id<SRConnectionInterface>)connection {
    [_webSocket setDelegate:nil];
    [_webSocket close];
    _webSocket = nil;
}

#pragma mark -
#pragma mark Websockets Transport

- (void)performConnect:(void (^)(id response, NSError *error))block {
    [self performConnect:block reconnecting:NO];
}

- (void)performConnect:(void (^)(id response, NSError *error))block reconnecting:(BOOL)reconnecting {
    
    id parameters = @{
        @"transport" : [self name],
        @"connectionToken" : [[_connectionInfo connection] connectionToken],
        @"messageId" : ([[_connectionInfo connection] messageId]) ? [[_connectionInfo connection] messageId] : @"",
        @"groupsToken" : ([[_connectionInfo connection] groupsToken]) ? [[_connectionInfo connection] groupsToken] : @"",
        @"connectionData" : ([_connectionInfo data]) ? [_connectionInfo data] : @"",
    };
    
    if ([[_connectionInfo connection] queryString]) {
        NSMutableDictionary *_parameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
        [_parameters addEntriesFromDictionary:[[_connectionInfo connection] queryString]];
        parameters = _parameters;
    }
    
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET" URLString:[_connectionInfo.connection.url stringByAppendingString:reconnecting ? @"reconnect" : @"connect"] parameters:parameters error:nil];
    [_connectionInfo.connection prepareRequest:request]; //TODO: prepareRequest
    
    SRLogWebSockets(@"WS: %@",[request.URL absoluteString]);
    
    [self setStartBlock:block];
    
    _webSocket = [[SRWebSocket alloc] initWithURLRequest:request];
    [_webSocket setDelegate:self];
    [_webSocket open];
}

#pragma mark -
#pragma mark SRWebSocketDelegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    SRLogWebSockets(@"Websocket Connected");
    
    // This will noop if we're not in the reconnecting state
    if ([[_connectionInfo connection] changeState:reconnecting toState:connected]) {
        [[_connectionInfo connection] didReconnect];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    SRLogWebSockets(@"WS Receive: %@", message);
    
    BOOL timedOut = NO;
    BOOL disconnected = NO;
    
    [self processResponse:_connectionInfo.connection response:message shouldReconnect:&timedOut disconnected:&disconnected];
    if (self.startBlock) {
        self.startBlock(nil,nil);
        self.startBlock = nil;
    }
    
    if (disconnected) {
        [[_connectionInfo connection] disconnect];
        [_webSocket close];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    SRLogWebSockets(@"Websocket Failed With Error %@, %@", [[_connectionInfo connection] connectionId], error);
    
    if (self.startBlock) {
        self.startBlock(nil,error);
        self.startBlock = nil;
    } else {
        [[_connectionInfo connection] didReceiveError:error];
        
        if ([SRConnection ensureReconnecting:[_connectionInfo connection]]) {
            [self performConnect:nil reconnecting:YES];
        }
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    SRLogWebSockets(@"WebSocket closed");
    
    if ([self tryCompleteAbort]) {
        return;
    }
    
    if ([SRConnection ensureReconnecting:[_connectionInfo connection]]) {
        [self performConnect:nil reconnecting:YES];
    }
}

@end
