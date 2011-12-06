//
//  SRWebSocket.h
//  SignalR
//
//  Created by Alex Billingsley on 10/24/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SRWebSocket;
@class GCDAysncSocket;

@protocol SRWebSocketDelegate<NSObject>
@optional 
- (void)webSocket:(SRWebSocket*)webSocket didFailWithError:(NSError*)error;
- (void)webSocketDidOpen:(SRWebSocket*)webSocket;
- (void)webSocketDidClose:(SRWebSocket*)webSocket;
- (void)webSocket:(SRWebSocket*)webSocket didReceiveMessage:(NSString*)message;
- (void)webSocketDidSendMessage:(SRWebSocket*)webSocket;
@end

@interface SRWebSocket : NSObject { }

@property (nonatomic, assign) id<SRWebSocketDelegate> delegate;

@property (nonatomic, getter=isConnected) BOOL connected;
@property (strong, nonatomic, readonly) NSURL* url;
@property (strong, nonatomic, readonly) NSString* origin;
@property (strong, nonatomic) GCDAysncSocket *socket;

+ (id)webSocketWithURLString:(NSString*)urlString delegate:(id<SRWebSocketDelegate>)delegate;
- (id)initWithURLString:(NSString*)urlString delegate:(id<SRWebSocketDelegate>)delegate;

- (void)open;
- (void)close;
- (void)send:(NSString*)message;

@end

enum {
    SRWebSocketErrorConnectionFailed = 1,
    SRWebSocketErrorHandshakeFailed = 2
};

extern NSString *const SRWebSocketException;
extern NSString* const SRWebSocketErrorDomain;
