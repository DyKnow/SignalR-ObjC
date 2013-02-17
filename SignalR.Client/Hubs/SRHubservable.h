//
//  SRHubservable.h
//  SignalR
//
//  Created by Alex Billingsley on 11/4/11.
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
#import "SRHubProxyInterface.h"

@class SRSubscription;

/**
 * An `SRHubservable` object provides interface for adding Subscriptions to an SRHubProxy
 */
@interface SRHubservable : NSObject

///-------------------------------
/// @name Properties
///-------------------------------

/**
 * An `NSString` object representing the name of the subscription event
 */
@property (strong, nonatomic, readonly) NSString *eventName;

/**
 * An `SRHubProxy` object representing the Hub to be observed
 */
@property (strong, nonatomic, readonly) id <SRHubProxyInterface> proxy;

///-------------------------------
/// @name Initializing an SRHubservable Object
///-------------------------------

/**
 * A convenience method for initWithProxy:(SRHubProxy *)proxy eventName:(NSString *)eventName;
 *
 * <code>
 *  SRHubservable *observable = [SRHubservable observe:myHub event:@"myEvent"];
 * </code>
 *
 * @param proxy the `SRHubProxy` object representing the Hub to be observed
 * @param eventName the `NSString` object representing the name of the subscription event
 * @return an `SRHubservable` object 
 */
+ (instancetype)observe:(id <SRHubProxyInterface>)proxy event:(NSString *)eventName;

/**
 * Initializes a new `SRHubservable` object
 *
 * <code>
 *  SRHubservable *observable = [SRHubservable observe:myHub event:@"myEvent"];
 * </code>
 *
 * @param proxy the `SRHubProxy` object representing the Hub to be observed
 * @param eventName the `NSString` object representing the name of the subscription event
 * @return an `SRHubservable` object 
 */
- (instancetype)initWithProxy:(id <SRHubProxyInterface>)proxy eventName:(NSString *)eventName;

///-------------------------------
/// @name Adding Subscriptions
///-------------------------------

/**
 * Adds a new Subscription to the underlying proxy for eventName
 *
 * @param object The receiver to perform selector on
 * @param selector A selector identifying the message to send.
 * @return the `SRSubscription` object created
 */
- (SRSubscription *)subscribe:(NSObject *)object selector:(SEL)selector;

@end
