//
//  SRWebSocket.h
//  SignalR
//
//  Created by Alex Billingsley on 10/24/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SRWebSocket;
@class AsyncSocket;

@protocol SRWebSocketDelegate<NSObject>
@optional 
- (void)webSocket:(SRWebSocket*)webSocket didFailWithError:(NSError*)error;
- (void)webSocketDidOpen:(SRWebSocket*)webSocket;
- (void)webSocketDidClose:(SRWebSocket*)webSocket;
- (void)webSocket:(SRWebSocket*)webSocket didReceiveMessage:(NSString*)message;
- (void)webSocketDidSendMessage:(SRWebSocket*)webSocket;
@end

@interface SRWebSocket : NSObject
{
    id<SRWebSocketDelegate> delegate;
    NSURL* url;
    AsyncSocket* socket;
    BOOL connected;
    NSString* origin;
    
    NSArray* runLoopModes;
}

@property(nonatomic,assign) id<SRWebSocketDelegate> delegate;
@property(nonatomic,readonly) NSURL* url;
@property(nonatomic,retain) NSString* origin;
@property(nonatomic,readonly) BOOL connected;
@property(nonatomic,retain) NSArray* runLoopModes;

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
