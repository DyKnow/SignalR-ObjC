//
//  SRHubRegistrationData.m
//  SignalR
//
//  Created by Alex Billingsley on 11/2/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "SRHubRegistrationData.h"

@interface SRHubRegistrationData ()

#define kName @"name"
#define kMethods @"methods"

@end

@implementation SRHubRegistrationData

@synthesize name = _name;
@synthesize methods = _methods;

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
	if (self = [self init])
	{
        self.name  = [NSString stringWithFormat:@"%@",[dict objectForKey:kName]];
        self.methods = [dict objectForKey:kMethods];
    }
    return self;
}

- (void)updateWithDictionary:(NSDictionary *)dict
{
    self.name = ([dict objectForKey:kName]) ? [NSString stringWithFormat:@"%@",[dict objectForKey:kName]] : _name;
    self.methods = ([dict objectForKey:kMethods]) ? [dict objectForKey:kMethods] : _methods;
}

- (id)proxyForJson
{
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    
    [dict setObject:[NSString stringWithFormat:@"%@",_name] forKey:kName];
    [dict setObject:_methods forKey:kMethods];
    
    return dict;
}

- (id)JSON
{
    return [self proxyForJson];
}

- (NSString *)description 
{     
    return [NSString stringWithFormat:@"HubRegistrationData: Name=%@ Methods=%@",_name,_methods];
}

- (void)dealloc
{
    _name = nil;
    _methods = nil;
}

@end
