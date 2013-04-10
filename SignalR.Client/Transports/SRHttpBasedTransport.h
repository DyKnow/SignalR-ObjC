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
#import "SRClientTransportInterface.h"
#import "SRHttpClient.h"
#import "SRRequest.h"

typedef void (^SRErrorByReferenceBlock)(NSError **);

/**
 * `SRHttpBasedTransport` is an abstract class intended to be subclassed. It publishes a programmatic interface that all subclasses must adopt and provide implementations for.
 * 
 * `SRHttpBasedTransport` is responsible for starting, sending data, processing server responses, and stopping the http based transports.
 */
@interface SRHttpBasedTransport : NSObject <SRClientTransportInterface>

///-------------------------------
/// @name Properties
///-------------------------------

@property (strong, nonatomic, readonly) id <SRHttpClient> httpClient;

///-------------------------------
/// @name Initializing an SRHttpBasedTransport Object
///-------------------------------

/**
 * Initializes a new `SRHttpBasedTransport`. 
 *
 * transport name is included in the query string of all `SRHttpBasedTransport`
 * some acceptible transport names include "serverSentEvents" and "longPolling"
 *
 * @param transport the name of the transport
 */
- (instancetype)initWithHttpClient:(id <SRHttpClient>)httpClient transport:(NSString *)transport;

/**
 * @warning *Important:* this method should only be called from a subclass of `SRHttpBasedTransport` 
 *
 * @param connection the `SRConnection` object that initialized the `SRHttpBasedTransport`
 * @param data the additional data to be sent to the server
 * @param initializeCallback a block to call when the `SRHttpBasedTransport` has been initialized successfully
 * @param errorCallback a block to call when the `SRHttpBasedTransport` failed to initialize successfully
 */
- (void)onStart:(id <SRConnectionInterface>)connection data:(NSString *)data initializeCallback:(void (^)(void))initializeCallback errorCallback:(void (^)(SRErrorByReferenceBlock))errorCallback;

///-------------------------------
/// @name Preparing requests
///-------------------------------

/**
 * Generates a query string for request made to receive data from the server
 *
 * @param connection the `SRConnection` object that initialized the `SRHttpBasedTransport`
 * @param data the additional data to be sent to the server
 * @return an URL encoded `NSString` object of the form ?transport=<transportname>&connectionId=<connectionId>&messageId=<messageId_or_Null>&groups=<groups>&connectionData=<data><customquerystring>
 */
- (NSString *)receiveQueryString:(id <SRConnectionInterface>)connection data:(NSString *)data;

@end
