//
//  SRHubRegistrationData.m
//  SignalR
//
//  Created by Alex Billingsley on 11/2/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "SRHubRegistrationData.h"

@interface SRHubRegistrationData()

#define kName @"name"
#define kMethods @"methods"

@end

@implementation SRHubRegistrationData

@synthesize name = _name;
@synthesize methods = _methods;

#pragma mark -
#pragma mark SRSBJSON Protocol

- (id) init
{
    if (self = [super init])
    {
        _name = [NSString stringWithFormat:@""];
		_methods = [NSMutableArray array];
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary*)dict
{
	self = [self init];
	if(self != nil)
	{
        _name  = [dict objectForKey:kName];
        _methods = [dict objectForKey:kMethods];
    }
    return self;
}

- (void)updateWithDictionary:(NSDictionary *)dict
{
	_name = [dict objectForKey:kName];
	_methods = [dict objectForKey:kMethods];
}

- (id)proxyForJson
{
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    
    [dict setObject:[NSString stringWithFormat:@"%@",_name] forKey:kName];
    [dict setObject:_methods forKey:kMethods];
    
    return dict;
}

- (NSString *)description 
{     
    return [NSString stringWithFormat:@"HubRegistrationData: Name=%@ Methods=%@",_name,_methods];
}

@end
