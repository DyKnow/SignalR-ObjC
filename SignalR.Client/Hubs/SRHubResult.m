//
//  SRHubResult.m
//  SignalR
//
//  Created by Alex Billingsley on 11/2/11.
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

#import "SRHubResult.h"

@interface SRHubResult ()

@end

@implementation SRHubResult

static NSString * const kId = @"I";
static NSString * const kResult = @"R";
static NSString * const kHubException = @"H";
static NSString * const kError = @"E";
static NSString * const kErrorData = @"D";
static NSString * const kState = @"S";

- (instancetype) init {
    if (self = [super init]) {
        _error = @"";
		_state = @{};
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary*)dict {
	if (self = [self init]) {
        self.id = dict[kId];
        self.result  = dict[kResult];
        self.hubException = (dict[kHubException] != nil) ? [dict[kHubException] boolValue] : NO;
        self.error = dict[kError];
        self.errorData = dict[kErrorData];
        self.state = dict[kState];
    }
    return self;
}

@end
