//
//  SRHttpBasedTransport.h
//  SignalR
//
//  Created by Alex Billingsley on 1/7/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRClientTransport+Constants.h"

#if NS_BLOCKS_AVAILABLE
typedef void (^SRErrorByReferenceBlock)(NSError **);
#endif

@interface SRHttpBasedTransport : NSObject <SRClientTransport>

@property (strong, nonatomic, readonly) NSString *transport;

- (id) initWithTransport:(NSString *)transport;

- (void)onStart:(SRConnection *)connection data:(NSString *)data initializeCallback:(void (^)(void))initializeCallback errorCallback:(void (^)(SRErrorByReferenceBlock))errorCallback;

- (BOOL)isRequestAborted:(NSError *)error;
- (NSString *)getReceiveQueryString:(SRConnection *)connection data:(NSString *)data;
- (NSString *)getSendQueryString:(SRConnection *)connection;
- (void)onBeforeAbort:(SRConnection *)connection;
- (void)processResponse:(SRConnection *)connection response:(NSString *)response timedOut:(BOOL *)timedOut disconnected:(BOOL *)disconnected;

- (void)prepareRequest:(id)request forConnection:(SRConnection *)connection;

#define kHttpRequestKey @"http.Request"

@end
