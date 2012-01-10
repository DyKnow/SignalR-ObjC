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

@synthesize hub = _hub;
@synthesize method = _method;
@synthesize args = _args;
@synthesize state = _state;

#pragma mark -
#pragma mark SRSBJSON Protocol

- (id) init
{
    if (self = [super init])
    {
        _hub = [NSString stringWithFormat:@""];
		_method = [NSString stringWithFormat:@""];
        _args = [NSMutableArray array];
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
        _method = [dict objectForKey:kMethod];
        _args = [dict objectForKey:kArgs];
        _state = [dict objectForKey:kState];
    }
    return self;
}

- (void)updateWithDictionary:(NSDictionary *)dict
{
	_hub = [dict objectForKey:kHub];
	_method = [dict objectForKey:kMethod];
    _args = [dict objectForKey:kArgs];
    _state = [dict objectForKey:kState];
}

- (id)proxyForJson
{
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    
    [dict setObject:[NSString stringWithFormat:@"%@",_hub] forKey:kHub];
    [dict setObject:[NSString stringWithFormat:@"%@",_method] forKey:kMethod];
    [dict setObject:_args forKey:kArgs];
    [dict setObject:_state forKey:kState];
    
    return dict;
}

- (NSString *)description 
{  
    return [NSString stringWithFormat:@"HubInvocation: Hub=%@ Method=%@",_hub,_method];
}
@end
