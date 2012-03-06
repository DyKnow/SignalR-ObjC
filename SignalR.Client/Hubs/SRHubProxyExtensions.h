//
//  SRHubProxyExtensions.h
//  SignalR
//
//  Created by Alex Billingsley on 11/10/11.
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
#import "SRHubProxy.h"

@class SRHubservable;
@class SRSubscription;

@interface SRHubProxy (Extensions)

/**
 * An extension method for accessing objects contained in the `SRHubProxy` state dictionary
 *
 * @param name the key for which to return the corresponding value.
 * 
 * @return Returns the value associated with a given key.
 */
- (id)getValue:(NSString *)name;

/**
 * Creates a new `SRSubscription` object
 *
 * @param eventName the name of the event to subscribe to
 * @param object The receiver to perform selector on
 * @param selector A selector identifying the message to send.
 * @return An instance of an `SRSubscription` object
 */
- (SRSubscription *)on:(NSString *)eventName perform:(NSObject *)object selector:(SEL)selector;

/**
 * Initalizes an `SRHubservable` with the specified eventName
 *
 * @param eventName the `NSString` object representing the name of the subscription event
 * @return an `SRHubservable` object 
 */
- (SRHubservable *)observe:(NSString *)eventName;

@end
