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

static NSString * const kCallbackId = @"I";
static NSString * const kHub = @"H";
static NSString * const kMethod = @"M";
static NSString * const kArgs = @"A";
static NSString * const kState = @"S";

- (instancetype) init {
    if (self = [super init]) {
        _callbackId = @"";
        _hub = [NSString stringWithFormat:@""];
		_method = [NSString stringWithFormat:@""];
        _args = [NSMutableArray array];
        _state = [NSMutableDictionary dictionary];
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary*)dict {
	if (self = [self init]) {
        self.callbackId = dict[kCallbackId];
        self.hub  = [NSString stringWithFormat:@"%@",dict[kHub]];
        self.method = [NSString stringWithFormat:@"%@",dict[kMethod]];
        self.args = dict[kArgs];
        self.state = dict[kState];
    }
    return self;
}

- (id)proxyForJson {
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    
    dict[kCallbackId] = _callbackId;
    dict[kHub] = [NSString stringWithFormat:@"%@",_hub];
    dict[kMethod] = [NSString stringWithFormat:@"%@",_method];
    dict[kArgs] = _args;
    dict[kState] = _state;
    
    return dict;
}

@end
