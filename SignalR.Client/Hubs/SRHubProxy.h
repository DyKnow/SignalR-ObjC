//
//  SRHubProxy.h
//  SignalR
//
//  Created by Alex Billingsley on 10/31/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SRConnection;
@class SRSubscription;

@interface SRHubProxy : NSObject

@property (strong, nonatomic, readonly) SRConnection *connection;
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
