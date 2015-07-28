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

#import <Foundation/Foundation.h>
#import "SRConnection.h"
#import "SRHubConnectionInterface.h"

@protocol SRHubProxyInterface;

/**
 * An `SRHubConnection` object provides an abstraction over `SRConnection` and provides support for publishing and subscribing to custom events
 */
@interface SRHubConnection : SRConnection <SRHubConnectionInterface>

- (instancetype)initWithURLString:(NSString *)URL useDefault:(BOOL)useDefault;
- (instancetype)initWithURLString:(NSString *)url queryString:(NSDictionary *)queryString useDefault:(BOOL)useDefault;

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
- (id <SRHubProxyInterface>)createHubProxy:(NSString *)hubName;

@end
