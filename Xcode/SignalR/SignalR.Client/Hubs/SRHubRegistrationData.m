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

@synthesize name;
@synthesize methods;

#pragma mark - Initialization

- (id)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
	if(self != nil)
	{
        name  = [dict objectForKey:kName];
        methods = [dict objectForKey:kMethods];
    }
    return self;
}

- (NSString *)description 
{     
    return [NSString stringWithFormat:@"HubRegistrationData: Name=%@ Methods=%@",name,methods];
}

- (void)updateWithDictionary:(NSDictionary *)dict
{
	name = [dict objectForKey:kName];
	methods = [dict objectForKey:kMethods];
}

- (id)proxyForJson
{
    NSMutableDictionary* dict = [[NSMutableDictionary alloc]init];
    if (name) [dict setObject:name forKey:kName];
    if (methods) [dict setObject:methods forKey:kMethods];
    
    return dict;
}


@end
