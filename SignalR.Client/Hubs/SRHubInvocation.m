//
//  SRHubInvocation.m
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

#import "SRHubInvocation.h"

@interface SRHubInvocation ()

@end

@implementation SRHubInvocation

@synthesize hub = _hub;
@synthesize method = _method;
@synthesize args = _args;
@synthesize state = _state;

static NSString * const kHub = @"Hub";
static NSString * const kMethod = @"Method";
static NSString * const kArgs = @"Args";
static NSString * const kState = @"State";

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
	if (self = [self init])
	{
        self.hub  = [NSString stringWithFormat:@"%@",[dict objectForKey:kHub]];
        self.method = [NSString stringWithFormat:@"%@",[dict objectForKey:kMethod]];
        self.args = [dict objectForKey:kArgs];
        self.state = [dict objectForKey:kState];
    }
    return self;
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

- (void)dealloc
{
    _hub = nil;
    _method = nil;
    _args = nil;
    _state = nil;
}

@end
