//
//  SRHttpBasedTransport.h
//  SignalR
//
//  Created by Alex Billingsley on 1/7/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRClientTransport.h"

@class ASIHTTPRequest;

@interface SRHttpBasedTransport : NSObject <SRClientTransport>

@property (strong, nonatomic, readonly) NSString *transport;

- (id) initWithTransport:(NSString *)transport;

- (void)onStart:(SRConnection *)connection data:(NSString *)data initializeCallback:(id)initializeCallback errorCallback:(id)errorCallback;

- (BOOL)isRequestAborted:(NSError *)error;
- (NSString *)getReceiveQueryString:(SRConnection *)connection data:(NSString *)data;
- (NSString *)getSendQueryString:(SRConnection *)connection;
- (void)onBeforeAbort:(SRConnection *)connection;
- (void)onMessage:(SRConnection *)connection response:(NSString *)response;

- (void)prepareRequest:(ASIHTTPRequest *)request forConnection:(SRConnection *)connection;

#define kHttpRequestKey @"http.Request"

@end
