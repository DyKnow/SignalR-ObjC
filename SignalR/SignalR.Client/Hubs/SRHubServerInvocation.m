//
//  SRHubServerInvocation.m
//  SignalR
//
//  Created by Alex Billingsley on 11/7/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "SRHubServerInvocation.h"

@interface SRHubServerInvocation()

#define kHub @"Hub"
#define kAction @"Action"
#define kData @"Data"
#define kState @"State"

@end

@implementation SRHubServerInvocation

@synthesize hub;
@synthesize action;
@synthesize data;
@synthesize state;

#pragma mark - Initialization

- (id)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
	if(self != nil)
	{
        hub  = [dict objectForKey:kHub];
        action = [dict objectForKey:kState];
        data = [dict objectForKey:kData];
        state = [dict objectForKey:kState];
    }
    return self;
}

- (NSString *)description 
{  
    return [NSString stringWithFormat:@"HubData: Hub=%@ Action=%@",hub,action];
}

- (void)updateWithDictionary:(NSDictionary *)dict
{
	hub = [dict objectForKey:kHub];
	action = [dict objectForKey:kAction];
    data = [dict objectForKey:kData];
    state = [dict objectForKey:kState];
}

- (id)proxyForJson
{
    NSMutableDictionary* dict = [[NSMutableDictionary alloc]init];
    if (hub) [dict setObject:hub forKey:kHub];
    if (action) [dict setObject:action forKey:kAction];
    if (data) [dict setObject:data forKey:kData];
    if (state) [dict setObject:state forKey:kState];
    
    return dict;
}

@end
