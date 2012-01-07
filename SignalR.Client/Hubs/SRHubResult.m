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

@synthesize result = _result;
@synthesize error = _error;
@synthesize state = _state;

#pragma mark -
#pragma mark SRSBJSON Protocol

- (id) init
{
    if (self = [super init])
    {
        _error = [NSString stringWithFormat:@""];
		_state = [NSDictionary dictionary];
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary*)dict
{
	self = [self init];
	if(self != nil)
	{
        _result  = [dict objectForKey:kResult];
        _error = [dict objectForKey:kError];
        _state = [dict objectForKey:kState];
    }
    return self;
}

- (void)updateWithDictionary:(NSDictionary *)dict
{
	_result = [dict objectForKey:kResult];
	_error = [dict objectForKey:kError];
    _state = [dict objectForKey:kState];
}

- (id)proxyForJson
{
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    
    [dict setObject:_result forKey:kResult];
    [dict setObject:[NSString stringWithFormat:@"%@",_error] forKey:kError];
    [dict setObject:_state forKey:kState];
    
    return dict;
}

- (NSString *)description 
{  
    return [NSString stringWithFormat:@"HubResult: Result:%@ Error=%@ State=%@",_result,_error,_state];
}

@end
