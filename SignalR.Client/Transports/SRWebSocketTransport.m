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

#import "SRWebSocketTransport.h"
#import "SRDefaultHttpClient.h"
#import "SRWebSocket.h"
#import "SRLog.h"
#import "SRWebSocketConnectionInfo.h"
#import "SRTransportHelper.h"
#import "SRConnectionInterface.h"

@interface SRWebSocketTransport () <SRWebSocketDelegate>

@property (strong, nonatomic, readonly) id <SRHttpClient> client;
@property (strong, nonatomic, readonly) SRWebSocketConnectionInfo *connectionInfo;

@end

@implementation SRWebSocketTransport

static NSString * const kTransportName = @"webSockets";

- (instancetype)init {
    if(self = [self initWithHttpClient:[[SRDefaultHttpClient alloc] init]]) {
    }
    return self;
}

- (instancetype)initWithHttpClient:(id<SRHttpClient>)httpClient {
    if (self = [super init]) {
        _client = httpClient;
        _reconnectDelay = @2;
    }
    return self;
}


- (NSString *)name {
    return kTransportName;
}

- (void)negotiate:(id <SRConnectionInterface>)connection completionHandler:(void (^)(SRNegotiationResponse *response))block {
    [SRTransportHelper getNegotiationResponse:_client connection:connection completionHandler:block];
}

- (void)start:(id <SRConnectionInterface>)connection withData:(NSString *)data completionHandler:(void (^)(id response))block {
    _connectionInfo = [[SRWebSocketConnectionInfo alloc] initConnection:connection data:data];
}

- (void)performConnect:(BOOL)reconnecting {
    NSString *urlString = (reconnecting) ? _connectionInfo.connection.url : [_connectionInfo.connection.url stringByAppendingString:@"connect"];
    urlString = [urlString stringByAppendingString:[SRTransportHelper receiveQueryString:_connectionInfo.connection data:_connectionInfo.data transport:[self name]]];
    
    NSURL *builder = [NSURL URLWithString:urlString];
    NSURL *url = [[NSURL alloc] initWithScheme:([builder.scheme isEqualToString:@"https"]) ? @"wss" : @"ws" host:[builder host] path:[builder path]];
    
    SRLogWebSocket(@"WS: %@",[url absoluteString]);
}

- (void)send:(id <SRConnectionInterface>)connection withData:(NSString *)data completionHandler:(void (^)(id response))block {
    
}

- (void)abort:(id <SRConnectionInterface>)connection {
    
}

#pragma mark - 
#pragma mark SRWebSocketDelegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket;
{
    SRLogWebSocket(@"Websocket Connected");
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
{
    SRLogWebSocket(@":( Websocket Failed With Error %@", error);
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message;
{
    SRLogWebSocket(@"Received \"%@\"", message);
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;
{
    SRLogWebSocket(@"WebSocket closed");
}

@end
