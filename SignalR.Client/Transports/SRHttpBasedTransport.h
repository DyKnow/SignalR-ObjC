//
//  SRHttpBasedTransport.h
//  SignalR
//
//  Created by Alex Billingsley on 1/7/12.
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
- (void)onMessage:(SRConnection *)connection response:(NSString *)response;

- (void)prepareRequest:(id)request forConnection:(SRConnection *)connection;

#define kHttpRequestKey @"http.Request"

@end
