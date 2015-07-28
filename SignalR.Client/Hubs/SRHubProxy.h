//
//  SRHubProxy.h
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
#import "SRHubConnectionInterface.h"
#import "SRHubProxyInterface.h"
    
/**
 * An `SRHubProxy` object provides support for SignalR Hubs
 */
@interface SRHubProxy : NSObject <SRHubProxyInterface>

@property (strong, nonatomic, readonly) NSMutableDictionary *state;

///-------------------------------
/// @name Initializing an SRHubProxy Object
///-------------------------------

/**
 * Initializes a new `SRHubProxy` object with the specified `SRConnection` and hubname
 *
 * @warning *Important* the hubname needs to be the full type name of the hub. 
 *
 * @param connection the connection to initialize the hub on
 * @param hubname an `NSString` representing the hubname 
 * @return an `SRHubProxy` object 
 */
- (instancetype)initWithConnection:(id <SRHubConnectionInterface>)connection hubName:(NSString *)hubname;

///-------------------------------
/// @name Subscription Management
///-------------------------------

/**
 * Invokes the `SRSubscription` object that corresponds to eventName
 *
 * @param eventName the `NSString` object representing the name of the subscription event
 * @param args the arguments to pass as part of the invocation
 */
- (void)invokeEvent:(NSString *)eventName withArgs:(NSArray *)args;

@end
