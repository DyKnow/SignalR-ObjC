//
//  SRHubProxyExtensions.h
//  SignalR
//
//  Created by Alex Billingsley on 11/10/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRHubProxy.h"

@class SRHubservable;
@class SRSubscription;

@interface SRHubProxy (Extensions)

- (id)getValue:(NSString *)name;
- (SRSubscription *)on:(NSString *)eventName perform:(NSObject *)object selector:(SEL)selector;
- (SRHubservable *)observe:(NSString *)eventName;

@end
