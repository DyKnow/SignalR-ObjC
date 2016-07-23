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

#ifndef NS_DESIGNATED_INITIALIZER
#if __has_attribute(objc_designated_initializer)
#define NS_DESIGNATED_INITIALIZER __attribute__((objc_designated_initializer))
#else
#define NS_DESIGNATED_INITIALIZER
#endif
#endif

#import <Foundation/Foundation.h>
#import "SRClientTransportInterface.h"

@interface SRHttpBasedTransport : NSObject <SRClientTransportInterface>

@property (strong, nonatomic, readonly) NSURLSessionConfiguration *sessionConfiguration;

- (instancetype)initWithSessionConfiguration:(nullable NSURLSessionConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

- (void)completeAbort;
- (BOOL)tryCompleteAbort;
- (void)processResponse:(id <SRConnectionInterface>)connection response:(NSString *)response shouldReconnect:(BOOL *)shouldReconnect disconnected:(BOOL *)disconnected;

//TODO: Move to Request Serializer
- (NSDictionary *)addTransport:(NSDictionary *)parameters transport:(NSString *)transport;
- (NSDictionary *)addConnectionData:(NSDictionary *)parameters connectionData:(NSString *)connectionData;
- (NSDictionary *)addConnectionToken:(NSDictionary *)parameters connection:(id <SRConnectionInterface>)connection;
- (NSDictionary *)addGroupsToken:(NSDictionary *)parameters connection:(id <SRConnectionInterface>)connection;
- (NSDictionary *)addMessageId:(NSDictionary *)parameters connection:(id <SRConnectionInterface>)connection;
- (NSDictionary *)addQueryString:(NSDictionary *)parameters connection:(id <SRConnectionInterface>)connection;

@end
