//
//  SRSubscription.m
//  SignalR
//
//  Created by Alex Billingsley on 11/2/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "SRSubscription.h"

@implementation SRSubscription

@synthesize object;
@synthesize selector;

- (NSString *)description 
{  
    return [NSString stringWithFormat:@"Subscription: Object:%@ Selector=%@",object, selector];
}

@end
