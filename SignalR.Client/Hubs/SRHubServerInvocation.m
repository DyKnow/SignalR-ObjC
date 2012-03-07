//
//  SRHubServerInvocation.m
//  SignalR
//
//  Created by Alex Billingsley on 11/7/11.
//  Copyright (c) 2011 DyKnow LLC. (http://dyknow.com/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
//  documentation files (the "Software"), to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and 
//  to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of 
//  the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
//  THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
//  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
//  DEALINGS IN THE SOFTWARE.
//

#import "SRHubServerInvocation.h"

@interface SRHubServerInvocation ()

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
	if (self = [self init])
	{
        self.hub  = [NSString stringWithFormat:@"%@",[dict objectForKey:kHub]];
        self.action = [NSString stringWithFormat:@"%@",[dict objectForKey:kState]];
        self.data = [dict objectForKey:kData];
        self.state = [dict objectForKey:kState];
    }
    return self;
}

- (void)updateWithDictionary:(NSDictionary *)dict
{
    self.hub = ([dict objectForKey:kHub]) ? [NSString stringWithFormat:@"%@",[dict objectForKey:kHub]] : _hub;
    self.action = ([dict objectForKey:kAction]) ? [NSString stringWithFormat:@"%@",[dict objectForKey:kAction]] : _action;
    self.data = ([dict objectForKey:kData]) ? [dict objectForKey:kData] : _data;
    self.state = ([dict objectForKey:kState]) ? [dict objectForKey:kState] : _state;
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

- (void)dealloc
{
    _hub = nil;
    _action = nil;
    _data = nil;
    _state = nil;
}
@end
