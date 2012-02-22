//
//  SRHubResult.m
//  SignalR
//
//  Created by Alex Billingsley on 11/2/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "SRHubResult.h"

@interface SRHubResult ()

#define kResult @"Result"
#define kError @"Error"
#define kState @"State"

@end

@implementation SRHubResult

@synthesize result = _result;
@synthesize error = _error;
@synthesize state = _state;

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
	if (self = [self init])
	{
        self.result  = [dict objectForKey:kResult];
        self.error = [dict objectForKey:kError];
        self.state = [dict objectForKey:kState];
    }
    return self;
}

- (void)updateWithDictionary:(NSDictionary *)dict
{
    self.result = ([dict objectForKey:kResult]) ? [dict objectForKey:kResult] : _result;
    self.error = ([dict objectForKey:kError]) ? [dict objectForKey:kError] : _error;
    self.state = ([dict objectForKey:kState]) ? [dict objectForKey:kState] : _state;
}

- (id)proxyForJson
{
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    
    [dict setObject:_result forKey:kResult];
    [dict setObject:[NSString stringWithFormat:@"%@",_error] forKey:kError];
    [dict setObject:_state forKey:kState];
    
    return dict;
}

- (id)JSON
{
    return [self proxyForJson];
}

- (NSString *)description 
{  
    return [NSString stringWithFormat:@"HubResult: Result:%@ Error=%@ State=%@",_result,_error,_state];
}

- (void)dealloc
{
    _result = nil;
    _error = nil;
    _state = nil;
}

@end
