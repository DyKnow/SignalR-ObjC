//
//  SRKeepAliveData.m
//  SignalR
//
//  Created by Alex Billingsley on 5/8/13.
//  Copyright (c) 2013 DyKnow LLC. (http://dyknow.com/)
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

#import "SRKeepAliveData.h"

@interface SRKeepAliveData ()

@end

@implementation SRKeepAliveData

- (instancetype)initWithTimeout:(NSNumber *)timeout {
    if (self = [super init]) {
        _timeout = timeout;
        _timeoutWarning = [NSNumber numberWithInteger:([_timeout integerValue] * (2.0 / 3.0))];
        _checkInterval = [NSNumber numberWithInteger:(([_timeout integerValue] - [_timeoutWarning integerValue]) / 3)];
    }
    return self;
}

- (instancetype)initWithLastKeepAlive:(NSDate *)lastKeepAlive timeout:(NSNumber *)timeout timeoutWarning:(NSNumber *)timeoutWarning checkInterval:(NSNumber *)checkInterval {
    if (self = [super init]) {
        _lastKeepAlive = lastKeepAlive;
        _timeout = timeout;
        _timeoutWarning = timeoutWarning;
        _checkInterval = checkInterval;
    }
    return self;
}
@end
