//
//  SRHubservable.h
//  SignalR
//
//  Created by Alex Billingsley on 11/4/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SRHubProxy;
@class SRSubscription;

@interface SRHubservable : NSObject

@property (strong, nonatomic, readonly) NSString *eventName;
@property (strong, nonatomic, readonly) SRHubProxy *proxy;

+ (id)observe:(SRHubProxy *)proxy event:(NSString *)eventName;
- (id)initWithProxy:(SRHubProxy *)proxy eventName:(NSString *)eventName;
- (SRSubscription *)subscribe:(NSObject *)object selector:(SEL)selector;

@end
