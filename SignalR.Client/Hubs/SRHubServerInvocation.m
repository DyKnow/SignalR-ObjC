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

@synthesize hub = _hub;
@synthesize action = _action;
@synthesize data = _data;
@synthesize state = _state;

#pragma mark -
#pragma mark SRSBJSON Protocol

- (id) init
{
    if (self = [super init])
    {
        _hub = [NSString stringWithFormat:@""];
		_action = [NSString stringWithFormat:@""];
        _data = [NSMutableArray array];
        _state = [NSMutableDictionary dictionary];
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary*)dict
{
	self = [self init];
	if(self != nil)
	{
        _hub  = [dict objectForKey:kHub];
        _action = [dict objectForKey:kState];
        _data = [dict objectForKey:kData];
        _state = [dict objectForKey:kState];
    }
    return self;
}

- (void)updateWithDictionary:(NSDictionary *)dict
{
	_hub = [dict objectForKey:kHub];
	_action = [dict objectForKey:kAction];
    _data = [dict objectForKey:kData];
    _state = [dict objectForKey:kState];
}

- (id)proxyForJson
{
    NSMutableDictionary* dict = [[NSMutableDictionary alloc]init];

    [dict setObject:[NSString stringWithFormat:@"%@",_hub] forKey:kHub];
    [dict setObject:[NSString stringWithFormat:@"%@",_action] forKey:kAction];
    [dict setObject:_data forKey:kData];
    [dict setObject:_state forKey:kState];
    
    return dict;
}

- (NSString *)description 
{  
    return [NSString stringWithFormat:@"HubData: Hub=%@ Action=%@",_hub,_action];
}

@end
