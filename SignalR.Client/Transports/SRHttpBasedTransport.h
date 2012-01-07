//
//  SRHttpBasedTransport.h
//  SignalR
//
//  Created by Alex Billingsley on 1/7/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import "SRClientTransport.h"

@interface SRHttpBasedTransport : NSObject <SRClientTransport>

@property (strong, nonatomic, readonly) NSString *transport;

- (id) initWithTransport:(NSString *)transport;

- (void)onStart:(SRConnection *)connection data:(NSString *)data;

- (BOOL)isRequestAborted:(NSError *)error;
- (NSString *)getReceiveQueryString:(SRConnection *)connection data:(NSString *)data;
- (NSString *)getSendQueryString:(SRConnection *)connection;
- (void)onBeforeAbort:(SRConnection *)connection;
- (void)onMessage:(SRConnection *)connection response:(NSString *)response;

#define kHttpRequestKey @"http.Request"

@end
