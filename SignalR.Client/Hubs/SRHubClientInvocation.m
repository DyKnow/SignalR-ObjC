//
//  SRHubClientInvocation.m
//  SignalR
//
//  Created by Alex Billingsley on 11/7/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "SRHubClientInvocation.h"

@interface SRHubClientInvocation()

#define kHub @"Hub"
#define kMethod @"Method"
#define kArgs @"Args"
#define kState @"State"

@end

@implementation SRHubClientInvocation

@synthesize hub;
@synthesize method;
@synthesize args;
@synthesize state;

#pragma mark - Initialization

- (id)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
	if(self != nil)
	{
        hub  = [dict objectForKey:kHub];
        method = [dict objectForKey:kMethod];
        args = [dict objectForKey:kArgs];
        state = [dict objectForKey:kState];
    }
    return self;
}

- (NSString *)description 
{  
    return [NSString stringWithFormat:@"HubInvocation: Hub=%@ Method=%@",hub,method];
}

- (void)updateWithDictionary:(NSDictionary *)dict
{
	hub = [dict objectForKey:kHub];
	method = [dict objectForKey:kMethod];
    args = [dict objectForKey:kArgs];
    state = [dict objectForKey:kState];
}

- (id)proxyForJson
{
    NSMutableDictionary* dict = [[NSMutableDictionary alloc]init];
    if (hub) [dict setObject:hub forKey:kHub];
    if (method) [dict setObject:method forKey:kMethod];
    if (args) [dict setObject:args forKey:kArgs];
    if (state) [dict setObject:state forKey:kState];
    
    return dict;
}

@end
