//
//  SRLongPollingTransport.h
//  SignalR
//
//  Created by Alex Billingsley on 10/17/11.
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
#import "SRHttpBasedTransport.h"

/**
 * `SRLongPollingTransport` object provides support for using Long Polling when communicating with a SignalR Server.
 * 
 * SRLongPollingTransport makes an HTTP POST Request with transport="longPolling"  `SRLongPollingTransport` will keep this connection open until it receives a response or 
 * a client side timeout, once the timeout is received `SRLongPollingTransport` will poll again after waiting for 2 seconds
 * Alternatively if the connection receives data successfully from the server, `SRLongPollingTransport` will poll the server again immediately
 */
@interface SRLongPollingTransport : SRHttpBasedTransport

///-------------------------------
/// @name Properties
///-------------------------------

/**
 * The time to wait after a connection drops to try reconnecting.
 *
 * By default, this is 5 seconds
 */
@property (strong, nonatomic, readwrite) NSNumber *reconnectDelay;

/**
 * The time to wait after an error happens to continue polling.
 *
 * By default, this is 2 seconds
 */
@property (strong, nonatomic, readwrite) NSNumber *errorDelay;

/**
 * The time to wait after the initial connect http request before it is considered open.
 *
 * By default, this is 2 seconds
 */
@property (strong, nonatomic, readwrite) NSNumber *connectDelay;


- (instancetype)initWithHttpClient:(id<SRHttpClient>)httpClient;

@end
