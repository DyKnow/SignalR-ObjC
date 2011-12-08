//
//  SRHubProxy.h
//  SignalR
//
//  Created by Alex Billingsley on 10/31/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRConnection.h"

#import "SRSubscription.h"
#import "SRHubServerInvocation.h"
#import "SRHubResult.h"

@class SRConnection;
@class SRSubscription;

@interface SRHubProxy : NSObject

@property (nonatomic, readonly, strong) SRConnection *connection;
@property (nonatomic, readonly, strong) NSString *hubName;
@property (nonatomic, readonly, strong) NSMutableDictionary *state;
@property (nonatomic, readonly, strong) NSMutableDictionary *subscriptions;

- (id)initWithConnection:(SRConnection *)connection hubName:(NSString *)hubname;

- (SRSubscription *)subscribe:(NSString *)eventName;
- (NSArray *)getSubscriptions;
- (void)invokeEvent:(NSString *)eventName withArgs:(NSArray *)args;

- (id)getMember:(NSString *)name;
- (void)setMember:(NSString *)name object:(id)value;
- (void)invoke:(NSString *)method withArgs:(NSArray *)args;
- (void)invoke:(NSString *)method withArgs:(NSArray *)args onCompletion:(void(^)(id data))responseBlock;

@end
