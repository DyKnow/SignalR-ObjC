//
//  SRHubProxy.m
//  SignalR
//
//  Created by Alex Billingsley on 10/31/11.
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
#import "SRHubProxy.h"
#import "SRHubResult.h"
#import "SRLog.h"
#import "SRSubscription.h"
#import "SRHubConnectionInterface.h"

@interface SRHubProxy ()

@property (assign, nonatomic, readonly) id <SRHubConnectionInterface> connection;
@property (strong, nonatomic, readonly) NSString *hubName;
@property (strong, nonatomic, readonly) NSMutableDictionary *state;
@property (strong, nonatomic, readonly) NSMutableDictionary *subscriptions;


@end

@implementation SRHubProxy

#pragma mark - 
#pragma mark Initialization

- (instancetype)initWithConnection:(id <SRHubConnectionInterface>)connection hubName:(NSString *)hubname {
    if (self = [super init]) {
        _connection = connection;
        _hubName = hubname;
        _subscriptions = [[NSMutableDictionary alloc] init];
        _state = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - 
#pragma mark Subscription Management

- (SRSubscription *)subscribe:(NSString *)eventName {
    if(eventName == nil || [eventName isEqualToString:@""]) {
        [NSException raise:NSInvalidArgumentException format:NSLocalizedString(@"Argument eventName is null",@"NSInvalidArgumentException")];
    }
    
    SRSubscription *subscription = _subscriptions[eventName];
    if(subscription == nil) {
        subscription = [[SRSubscription alloc] init];
        _subscriptions[eventName] = subscription;
    }
    
    return subscription;
}

- (void)invokeEvent:(NSString *)eventName withArgs:(NSArray *)args {
    SRSubscription *eventObj = _subscriptions[eventName];
    if(eventObj != nil) {
        NSMethodSignature *signature = [eventObj.object methodSignatureForSelector:eventObj.selector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        NSUInteger numberOfArguments = [signature numberOfArguments] - 2;
        
        if (args.count != numberOfArguments) {
            SRLogConnection(@"Callback for event '%@' is configured with %ld arguments, received %ld parameters instead.",eventName, (unsigned long)numberOfArguments, (unsigned long)args.count);
        }
        
        [invocation setSelector:eventObj.selector];
        [invocation setTarget:eventObj.object];
        for(int i =0; i< MIN([args count], numberOfArguments); i++) {
            int arguementIndex = 2 + i;
            __weak NSString *argument = args[i];
            [invocation setArgument:&argument atIndex:arguementIndex];
        }
        [invocation invoke];
    }
}

#pragma mark - 
#pragma mark State Management

- (id)getMember:(NSString *)name {
    id value = _state[name];
    return value;
}

- (void)setMember:(NSString *)name object:(id)value {
    [_state setValue:value forKey:name];
}

- (void)invoke:(NSString *)method withArgs:(NSArray *)args {
    [self invoke:method withArgs:args completionHandler:nil];
}

- (void)invoke:(NSString *)method withArgs:(NSArray *)args completionHandler:(void (^)(id response))block {
    if(method == nil || [method isEqualToString:@""]) {
        [NSException raise:NSInvalidArgumentException format:NSLocalizedString(@"Argument method is null",@"NSInvalidArgumentException")];
    }
    
    if(args == nil) {
        [NSException raise:NSInvalidArgumentException format:NSLocalizedString(@"Argument args is null",@"NSInvalidArgumentException")];
    }
    
    NSString *callbackId = [_connection registerCallback:^(SRHubResult *hubResult) {
        if (hubResult != nil) {
            if(![hubResult.error isKindOfClass:[NSNull class]] && hubResult.error != nil) {
                NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
                userInfo[NSLocalizedFailureReasonErrorKey] = NSInternalInconsistencyException;
                userInfo[NSLocalizedDescriptionKey] = [NSString stringWithFormat:@"%@",hubResult.error];
                NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:NSLocalizedString(@"com.SignalR-ObjC.%@",@""),NSStringFromClass([self class])]
                                                     code:0
                                                 userInfo:userInfo];
                [_connection didReceiveError:error];
            }
            
            if(![hubResult.state isKindOfClass:[NSNull class]] && hubResult.state != nil) {
                for (id key in hubResult.state) {
                    [self setMember:key object:(hubResult.state)[key]];
                }
            }
            
            if (block != nil) {
                block(hubResult.result);
            }
        }
    }];
    
    SRHubInvocation *hubData = [[SRHubInvocation alloc] init];
    hubData.hub = _hubName;
    hubData.method = method;
    hubData.args = [NSMutableArray arrayWithArray:args];
    hubData.callbackId = callbackId;
    
    if (_state.count > 0) {
        hubData.state = _state;
    }
    
    [_connection send:hubData];
}

- (NSString *)description {     
    return [NSString stringWithFormat:@"HubProxy: Name=%@ State=%@ Subscriptions:%@",_hubName,_state,_subscriptions];
}

@end
