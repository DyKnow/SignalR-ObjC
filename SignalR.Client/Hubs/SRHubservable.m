//
//  SRHubservable.m
//  SignalR
//
//  Created by Alex Billingsley on 11/4/11.
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

#import "SRHubservable.h"
#import "SRSubscription.h"

@interface SRHubservable ()

@end

@implementation SRHubservable

#pragma mark - 
#pragma mark Initialization

+ (instancetype)observe:(id <SRHubProxyInterface>)proxy event:(NSString *)eventName {
    return [[SRHubservable alloc] initWithProxy:proxy eventName:eventName];
}

- (instancetype)initWithProxy:(id <SRHubProxyInterface>)proxy eventName:(NSString *)eventName {
    if (self = [super init]) {
        _proxy = proxy;
        _eventName = eventName;
    }
    return self;
}

- (SRSubscription *)subscribe:(NSObject *)object selector:(SEL)selector {
    SRSubscription *subscription = [_proxy subscribe:_eventName];
    subscription.object = object;
    subscription.selector = selector;
    
    return subscription;
}

- (NSString *)description {  
    return [NSString stringWithFormat:@"Hubservable: Hub:%@ Event=%@",_proxy, _eventName];
}

@end
