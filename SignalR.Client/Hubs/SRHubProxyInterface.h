//
//  SRHubProxyInterface.h
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

@class SRSubscription;

@protocol SRHubProxyInterface <NSObject>

///-------------------------------
/// @name Subscribe
///-------------------------------

/**
 * Creates a new `SRSubscription` object
 *
 * @param eventName the name of the event to subscribe to
 * @param object The receiver to perform selector on
 * @param selector A selector identifying the message to send.
 * @return An instance of an `SRSubscription` object
 */
- (SRSubscription *)on:(NSString *)eventName perform:(NSObject *)object selector:(SEL)selector;


///-------------------------------
/// @name Publish
///-------------------------------

/**
 * Invokes a SignalR Server Hub method with the specified method name and arguments
 * calls [self inoke:method arg:args completionHandler];
 *
 * @param method the `NSString` object representing the name of the server method to invoke
 * @param args the arguments to pass as part of the invocation
 */
- (void)invoke:(NSString *)method withArgs:(NSArray *)args;

/**
 * Invokes a SignalR Server Hub method with the specified method name and arguments
 *
 * @param method the `NSString` object representing the name of the server method to invoke
 * @param args the arguments to pass as part of the invocation
 * @param block the block to be called once the server method is invoked, this may be nil
 */
- (void)invoke:(NSString *)method withArgs:(NSArray *)args completionHandler:(void (^)(id response, NSError *error))block;

@end
