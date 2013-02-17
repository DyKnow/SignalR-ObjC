//
//  SRServerSentEventsTransport.h
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
#import "SRHttpBasedTransport.h"

/**
 * `SRServerSentEventsTransport` object provides support for using [Server-Sent Events](http://dev.w3.org/html5/eventsource/) when communicating with a SignalR Server.
 * 
 * SRServerSentEvents makes an HTTP Get Request with transport="serverSentEvents"  `SRServerSentEventsTransport` will keep this connection open until it receives a timeout message from the server
 * once the timeout is received `SRServerSentEventsTransport` will attempt a reconnect after waiting for 2 seconds
 * 
 * @warning *Important:* a client side timeout will occur after 240 seconds, it is important that the ReconnectTimeout defined in DefaultConfigurationManager.cs on the server does not exceed 240 seconds
 * If a client side timeout occurs before the server side timeout SRServerSentEvents transport will not reconnect
 */
@interface SRServerSentEventsTransport : SRHttpBasedTransport

///-------------------------------
/// @name Properties
///-------------------------------

/**
 * Returns an `NSInteger` object with the time allowed before failing the connect request.
 *
 * By default, this is 2 seconds
 */
@property (strong, nonatomic, readwrite) NSNumber *connectionTimeout;

/**
 * Returns an `NSInteger` object with the time to wait after a connection drops to try reconnecting.
 *
 * By default, this is 2 seconds
 */
@property (strong, nonatomic, readwrite) NSNumber *reconnectDelay;

- (instancetype)initWithHttpClient:(id<SRHttpClient>)httpClient;

@end
