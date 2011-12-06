//
//  SRHubResult.m
//  SignalR
//
//  Created by Alex Billingsley on 11/2/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "SRHubResult.h"

@interface SRHubResult()

#define kResult @"Result"
#define kError @"Error"
#define kState @"State"

@end

@implementation SRHubResult

@synthesize result;
@synthesize error;
@synthesize state;

#pragma mark - Initialization

- (id)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
	if(self != nil)
	{
        result  = [dict objectForKey:kResult];
        error = [dict objectForKey:kError];
        state = [dict objectForKey:kState];
    }
    return self;
}

- (NSString *)description 
{  
    return [NSString stringWithFormat:@"HubResult: Result:%@ Error=%@ State=%@",result,error,state];
}

- (void)updateWithDictionary:(NSDictionary *)dict
{
	result = [dict objectForKey:kResult];
	error = [dict objectForKey:kError];
    state = [dict objectForKey:kState];
}

- (id)proxyForJson
{
    NSMutableDictionary* dict = [[NSMutableDictionary alloc]init];
    if (result) [dict setObject:result forKey:kResult];
    if (error) [dict setObject:error forKey:kError];
    if (state) [dict setObject:state forKey:kState];
    
    return dict;
}

@end
