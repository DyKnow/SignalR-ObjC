//
//  SRTransport.h
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
#import "SRClientTransport.h"

/**
 * `SRTransport` object provides convenient access to all supported transports
 */
@interface SRTransport : NSObject

///-------------------------------
/// @name Properties
///-------------------------------

/**
 * Returns an `SRAutoTransport` object
 */
@property (strong, nonatomic, readwrite) id <SRClientTransport> autoTransport;

/**
 * Returns an `SRServerSentEventsTransport` object
 */
@property (strong, nonatomic, readonly) id <SRClientTransport> serverSentEvents;

/**
 * Returns an `SRLongPollingTransport` object
 */
@property (strong, nonatomic, readonly) id <SRClientTransport> longPolling;

/**
 * Convenience method for returning an instance of `SRAutoTransport`
 *
 * @return an instance of `SRAutoTransport`
 */
+ (id <SRClientTransport>)Auto;

/**
 * Convenience method for returning an instance of `SRServerSentEventsTransport`
 *
 * @return an instance of `SRServerSentEventsTransport`
 */
+ (id <SRClientTransport>)ServerSentEvents;

/**
 * Convenience method for returning an instance of `SRLongPollingTransport`
 *
 * @return an instance of `SRLongPollingTransport`
 */
+ (id <SRClientTransport>)LongPolling;

@end
