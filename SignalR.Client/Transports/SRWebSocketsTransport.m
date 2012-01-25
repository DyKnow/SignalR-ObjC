//
//  SRWebSocketsTransport.m
//  SignalR
//
//  Created by Alex Billingsley on 10/24/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "SRWebSocketsTransport.h"
#import "SBJson.h"
#import "SRWebSocket.h"

@interface SRWebSocketsTransport()

@end

@implementation SRWebSocketsTransport

- (void)start:(SRConnection *)connection
{

}

- (void)send:(SRConnection *)connection withData:(NSString *)data onCompletion:(void(^)(SRConnection *, id))block;
{

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
