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
@property (strong, nonatomic, readwrite) NSBlockOperation * connectTimeoutOperation;

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
    SRLogWSDebug(@"websocket will negotiate");
    [super negotiate:connection connectionData:connectionData completionHandler:block];
}

- (void)start:(id<SRConnectionInterface>)connection connectionData:(NSString *)connectionData completionHandler:(void (^)(id response, NSError *error))block {
    SRLogWSDebug(@"websocket will connect with connectionData %@", connectionData);
    _connectionInfo = [[SRWebSocketConnectionInfo alloc] initConnection:connection data:connectionData];
    [self performConnect:block];
}

- (void)send:(id<SRConnectionInterface>)connection data:(NSString *)data connectionData:(NSString *)connectionData completionHandler:(void (^)(id response, NSError *error))block {
    SRLogWSDebug(@"will send data on websocket %@", data);
    [_webSocket send:data];
    
    if(block) {
        block(nil,nil);
    }
}

- (void)abort:(id <SRConnectionInterface>)connection timeout:(NSNumber *)timeout connectionData:(NSString *)connectionData {
    SRLogWSDebug(@"abort, will close websocket");
    [self stopWebsocket];
    [super abort:connection timeout:timeout connectionData:connectionData];
}

- (void)lostConnection:(id<SRConnectionInterface>)connection {
    SRLogWSWarn(@"lost connection, closing websocket");
    [self stopWebsocket];
    
    if ([self tryCompleteAbort]) {
        return;
    }
    
    [self reconnect:[_connectionInfo connection]];
}

- (void)stopWebsocket {
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
        @"connectionToken" : ([[_connectionInfo connection] connectionToken]) ? [[_connectionInfo connection] connectionToken] :@"",
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
    
    SRLogWSDebug(@"websocket will connect at url: %@",[request.URL absoluteString]);
    
    [self setStartBlock:block];
    if (self.startBlock) {
        __weak __typeof(&*self)weakSelf = self;
        self.connectTimeoutOperation = [NSBlockOperation blockOperationWithBlock:^{
            __strong __typeof(&*weakSelf)strongSelf = weakSelf;
            if (strongSelf.startBlock) {
                NSDictionary* userInfo = @{
                    NSLocalizedDescriptionKey: NSLocalizedString(@"Connection timed out.", nil),
                    NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Connection did not receive initialized message before the timeout.", nil),
                    NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Retry or switch transports.", nil)
                };
                NSError *timeout = [[NSError alloc]initWithDomain:[NSString stringWithFormat:NSLocalizedString(@"com.SignalR.SignalR-ObjC.%@",@""),NSStringFromClass([self class])] code:NSURLErrorTimedOut userInfo:userInfo];
                SRLogWSError(@"websocket failed to receive initialized message before timeout");
                [strongSelf stopWebsocket];
                
                SRWebSocketStartBlock callback = [strongSelf.startBlock copy];
                strongSelf.startBlock = nil;
                callback(nil,timeout);
            }
        }];
        [self.connectTimeoutOperation performSelector:@selector(start) withObject:nil afterDelay:[[[_connectionInfo connection] transportConnectTimeout] integerValue]];
    }
    _webSocket = [[SRWebSocket alloc] initWithURLRequest:request];
    [_webSocket setDelegate:self];
    [_webSocket open];
}

- (void)reconnect:(id <SRConnectionInterface>)connection {
    __weak __typeof(&*self)weakSelf = self;
    SRLogWSDebug(@"will reconnect in %@",self.reconnectDelay);
    [[NSBlockOperation blockOperationWithBlock:^{
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        
        if ([SRConnection ensureReconnecting:connection]) {
            SRLogWSWarn(@"reconnecting");
            [strongSelf performConnect:nil reconnecting:YES];
        }
        
    }] performSelector:@selector(start) withObject:nil afterDelay:[self.reconnectDelay integerValue]];
}

#pragma mark -
#pragma mark SRWebSocketDelegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    SRLogWSInfo(@"websocket did open");
    
    // This will noop if we're not in the reconnecting state
    if ([[_connectionInfo connection] changeState:reconnecting toState:connected]) {
        [[_connectionInfo connection] didReconnect];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    SRLogWSInfo(@"websocket did receive: %@", message);
    
    BOOL timedOut = NO;
    BOOL disconnected = NO;
    
    [self processResponse:_connectionInfo.connection response:message shouldReconnect:&timedOut disconnected:&disconnected];
    if (self.startBlock) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self.connectTimeoutOperation
                                                 selector:@selector(start)
                                                   object:nil];
        self.connectTimeoutOperation = nil;
        
        SRWebSocketStartBlock callback = [self.startBlock copy];
        self.startBlock = nil;
        callback(nil,nil);
    }
    
    if (disconnected) {
        SRLogWSDebug(@"websocket did receive disconnect command from server, will close");
        [[_connectionInfo connection] disconnect];
        [self stopWebsocket];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    SRLogWSError(@"websocket did fail with error %@, %@", [[_connectionInfo connection] connectionId], error);
    
    if (self.startBlock) {
        SRLogWSDebug(@"websocket did fail while connecting");
        [NSObject cancelPreviousPerformRequestsWithTarget:self.connectTimeoutOperation
                                                 selector:@selector(start)
                                                   object:nil];
        self.connectTimeoutOperation = nil;
        [self stopWebsocket];
        
        SRWebSocketStartBlock callback = [self.startBlock copy];
        self.startBlock = nil;
        callback(nil,error);
    } else if ([[_connectionInfo connection] state] == reconnecting) {
        SRLogWSWarn(@"transport already reconnecting");
    }else if (!self.startedAbort) {
        SRLogWSWarn(@"will reconnect from errors: %@", error);
        [self reconnect:[_connectionInfo connection]];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    if (wasClean) {
        SRLogWSWarn(@"websocket did close cleanly with %ld reason %@", (long)code, reason);
    } else {
        SRLogWSError(@"websocket did close with %ld reason %@", (long)code, reason);
    }
    
    if ([self tryCompleteAbort]) {
        return;
    }
    
    [self reconnect:[_connectionInfo connection]];
}

@end
