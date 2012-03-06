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

@interface SRHubProxy : NSObject

///-------------------------------
/// @name Properties
///-------------------------------

/**
 * The `SRConnection` object cooresponding to underlying SRConnection
 */
@property (strong, nonatomic, readonly) SRConnection *connection;

/**
 * The `NSString` object cooresponding to the hubname
 */
@property (strong, nonatomic, readonly) NSString *hubName;
@property (strong, nonatomic, readonly) NSMutableDictionary *state;
@property (strong, nonatomic, readonly) NSMutableDictionary *subscriptions;

- (id)initWithConnection:(SRConnection *)connection hubName:(NSString *)hubname;

- (SRSubscription *)subscribe:(NSString *)eventName;
- (NSArray *)getSubscriptions;
- (void)invokeEvent:(NSString *)eventName withArgs:(NSArray *)args;

- (id)getMember:(NSString *)name;
- (void)setMember:(NSString *)name object:(id)value;
- (void)invoke:(NSString *)method withArgs:(NSArray *)args;
- (void)invoke:(NSString *)method withArgs:(NSArray *)args continueWith:(void(^)(id data))responseBlock;

@end
