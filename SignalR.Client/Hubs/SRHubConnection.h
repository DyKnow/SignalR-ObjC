//
//  SRHubConnection.h
//  SignalR
//
//  Created by Alex Billingsley on 10/31/11.
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

#import "SRConnection.h"

@class SRHubProxy;

/**
 * An `SRHubConnection` object provides an abstraction over `SRConnection` and provides support for publishing and subscribing to custom events
 */
@interface SRHubConnection : SRConnection

///-------------------------------
/// @name Properties
///-------------------------------

/**
 * The `NSMutableDictionary` object containing the `SRHubProxy` objects
 */
@property (strong, nonatomic, readonly) NSMutableDictionary *hubs;

/**
 * A convenience method for initWithURL:(NSString *)url;
 *
 * <code>
 *  SRHubConnection *connection = [SRHubConnection connectionWithURL:@"http://mysite/"];
 * </code>
 * @warning *Important:*  This url will not point to a specific handler. But will instead point to the root of your site.
 *
 * @param URL the endpoint to initialize the new connection to
 * @return an SRHubConnection object 
 */
+ (SRHubConnection *)connectionWithURL:(NSString *)URL;

/**
 * Initializes a new `SRHubConnection` object at the specified URL
 * 
 * <code>
 *  SRHubConnection *connection = [[SRHubConnection alloc] initWithURL:@"http://mysite/"];
 * </code>
 * @warning *Important:*  This url will not point to a specific handler. But will instead point to the root of your site.
 *
 * @param url the endpoint to initialize the new connection to
 * @return an SRHubConnection object 
 */
- (id)initWithURL:(NSString *)url;

/**
 * Creates a client side proxy to the hub on the server side.
 *
 * <code>
 *  SRHubProxy *myHub = [connection createProxy:@"MySite.MyHub"];
 * </code>
 * @warning *Important:* The name of this hub needs to be the full type name of the hub.
 *
 * @param hubName hubName the name of the hub
 * @return SRHubProxy object 
 */
- (SRHubProxy *)createProxy:(NSString *)hubName;

/**
 * Starts the connection for all hubs
 * @param transport the transport to use for the connection
 */
- (void)start:(id<SRClientTransport>)transport;

/**
 * Stops the connection for all hubs
 */
- (void)stop;

@end
