//
//  SRWebSocketsTransport.m
//  SignalR
//
//  Created by Alex Billingsley on 10/24/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "SRWebSocketsTransport.h"
#import "SBJson.h"

@interface SRWebSocketsTransport()

@end

@implementation SRWebSocketsTransport

@synthesize socket;

- (void)start:(SRConnection *)connection
{
    NSURL *connectionUrl = [NSURL URLWithString:connection.url];
    NSString *url = [NSString stringWithFormat:@"ws://%@:%d%@", [connectionUrl host],[[connectionUrl port] intValue],connection.appRelativeUrl];
    
    if(connection.data){
        url = [url stringByAppendingFormat:@"?"];
        url = [url stringByAppendingFormat:@"%@=%@&",kConnectionData,connection.data];
        url = [url stringByAppendingFormat:@"%@=%@&",kTransport,kWebSocketsTransport];
        url = [url stringByAppendingFormat:@"%@=%@",kClientId,connection.clientId];
    }
    else{
        url = [url stringByAppendingFormat:@"?"];
        url = [url stringByAppendingFormat:@"%@=%@&",kTransport,kWebSocketsTransport];
        url = [url stringByAppendingFormat:@"%@=%@",kClientId,connection.clientId];
    }
    
#if DEBUG
    //connects to demo located here: http://websocket.org/echo.html
    //url = @"ws://echo.websocket.org:80";
    NSLog(@"%@",url);
#endif
    
    self.socket = [[SRWebSocket alloc] initWithURLString:url delegate:self];
    [self.socket open];
}

- (void)send:(SRConnection *)connection withData:(NSString *)data
{
    [self.socket send:data];
}

- (void)stop:(SRConnection *)connection
{
    
}

#pragma mark - SRWebSocket delegate methods

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
#if DEBUG
    NSLog(@"OPENED");
#endif
}

- (void)webSocketDidClose:(SRWebSocket*)webSocket;
{
#if DEBUG
    NSLog(@"CLOSED");
#endif
}

- (void)webSocket:(SRWebSocket*)webSocket didReceiveMessage:(NSString*)message;
{
#if DEBUG
    NSLog(@"SUCCESS :%@",message);
#endif
}

- (void)webSocketDidSendMessage:(SRWebSocket *)webSocket
{
#if DEBUG
    NSLog(@"SENT MESSAGE");
#endif
}

- (void)webSocket:(SRWebSocket*)webSocket didFailWithError:(NSError*)error;
{
#if DEBUG
    NSLog(@"FAILED %@",error);
#endif
}

@end
