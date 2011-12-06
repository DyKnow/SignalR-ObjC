//
//  SRHubProxyExtensions.m
//  SignalR
//
//  Created by Alex Billingsley on 11/10/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "SRHubProxyExtensions.h"

@implementation SRHubProxy (SRHubProxyExtensions)

- (id)getValue:(NSString *)name
{
    id value = [self getMember:name];
    return value;
}

- (SRSubscription *)on:(NSString *)eventName perform:(NSObject *)object selector:(SEL)selector
{
    SRSubscription *subscription = [self subscribe:eventName];
    subscription.object = object;
    subscription.selector = selector;
    
    return subscription;
}

- (SRHubservable *)observe:(NSString *)eventName
{
    return [[SRHubservable alloc] initWithProxy:self eventName:eventName];
}

@end
