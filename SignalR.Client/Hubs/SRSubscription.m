//
//  SRSubscription.m
//  SignalR
//
//  Created by Alex Billingsley on 11/2/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "SRSubscription.h"

@interface SRSubscription ()

@end

@implementation SRSubscription

@synthesize object = _object;
@synthesize selector = _selector;

- (NSString *)description 
{  
    return [NSString stringWithFormat:@"Subscription: Object:%@ Selector=%@",_object, _selector];
}

- (void)dealloc
{
    _object = nil;
    _selector = nil;
}

@end
