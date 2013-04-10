//
//  SRTransportHelper.h
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

#import <Foundation/Foundation.h>
#import "SRHttpClient.h"
#import "SRConnectionInterface.h"
#import "SRNegotiationResponse.h"

@interface SRTransportHelper : NSObject

+ (void)getNegotiationResponse:(id <SRHttpClient>)httpClient connection:(id <SRConnectionInterface>)connection completionHandler:(void (^)(SRNegotiationResponse *response))block;
+ (NSString *)receiveQueryString:(id <SRConnectionInterface>)connection data:(NSString *)data transport:(NSString *)transport;

///-------------------------------
/// @name Processing a response
///-------------------------------

/**
 * Processes a successful server response by updating relevant connection properties and dispatching calls to [SRConnection didReceiveData]
 *
 * @param connection the `SRConnection` object that initialized the `SRHttpBasedTransport`
 * @param response an `NSString` representation of the server's JSON response object
 * @param timedOut a `BOOL` respresenting if the connection received a server side timeout
 * @param disconnected a `BOOL` respresenting if the connection received a disconnect from the server
 */
+ (void)processResponse:(id <SRConnectionInterface>)connection response:(NSString *)response timedOut:(BOOL *)timedOut disconnected:(BOOL *)disconnected;

@end
