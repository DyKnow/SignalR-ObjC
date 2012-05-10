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

@class SRConnection;
@class SRSubscription;
    
/**
 * An `SRHubProxy` object provides support for SignalR Hubs
 */
@interface SRHubProxy : NSObject

///-------------------------------
/// @name Properties
///-------------------------------

/**
 * The `SRConnection` object corresponding to underlying `SRConnection`
 */
@property (assign, nonatomic, readonly) SRConnection *connection;

/**
 * The `NSString` object corresponding to the hubname
 */
@property (strong, nonatomic, readonly) NSString *hubName;

/**
 * An `NSMutableDictionary` object that manages the state of the SignalR Hub
 */
@property (strong, nonatomic, readonly) NSMutableDictionary *state;

/**
 * An `NSMutableDictionary` object that manages the `SRSubscriptions` that have been defined on the hub
 */
@property (strong, nonatomic, readonly) NSMutableDictionary *subscriptions;

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
- (id)initWithConnection:(SRConnection *)connection hubName:(NSString *)hubname;

///-------------------------------
/// @name Subscription Management
///-------------------------------

/**
 * Adds a new `SRSubscription` to the hubproxy for eventName
 *
 * @param eventName the `NSString` object representing the name of the subscription event
 * @return the `SRSubscription` object created
 */
- (SRSubscription *)subscribe:(NSString *)eventName;

/**
 * Invokes the `SRSubscription` object that corresponds to eventName
 *
 * @param eventName the `NSString` object representing the name of the subscription event
 * @param args the arguments to pass as part of the invocation
 */
- (void)invokeEvent:(NSString *)eventName withArgs:(NSArray *)args;

///-------------------------------
/// @name State Management
///-------------------------------

/**
 * Returns the object corresponding to name in the state dictionary
 *
 * @param name the key for which to return the corresponding value.
 * 
 * @return Returns the value associated with a given key.
 */
- (id)getMember:(NSString *)name;

/**
 * Adds a given key-value pair to the state dictionary.
 *
 * @param name The key for value
 * @param value The value for key.
 */
- (void)setMember:(NSString *)name object:(id)value;

/**
 * Invokes a SignalR Server Hub method with the specified method name and arguments
 * calls [self inoke:method arg:args continueWith:nil];
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
 * @param responseBlock the block to be called once the server method is invoked, this may be nil
 */
- (void)invoke:(NSString *)method withArgs:(NSArray *)args continueWith:(void(^)(id data))responseBlock;

@end
