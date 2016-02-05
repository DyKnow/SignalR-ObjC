//
//  SRHubConnection.m
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

#import "SRHubConnection.h"
#import "SRHubInvocation.h"
#import "SRHubProxy.h"
#import "SRHubRegistrationData.h"
#import "SRLog.h"
#import "SRHubResult.h"

#import "NSObject+SRJSON.h"

@interface SRHubConnection ()

@property (strong, nonatomic, readonly) NSMutableDictionary *hubs;
@property (strong, nonatomic, readonly) NSMutableDictionary *callbacks;
@property (assign, nonatomic, readonly) int callbackId;

+ (NSString *)getUrl:(NSString *)URL useDefault:(BOOL)useDefault;

@end

@implementation SRHubConnection

#pragma mark - 
#pragma mark Initialization

- (instancetype)initWithURLString:(NSString *)URL {
    return [self initWithURLString:URL useDefault:YES];
}

- (instancetype)initWithURLString:(NSString *)URL useDefault:(BOOL)useDefault {
    if (self = [super initWithURLString:[[self class] getUrl:URL useDefault:useDefault]])  {
		[self commonInit];
    }
    return self;
}

- (instancetype)initWithURLString:(NSString *)url queryString:(NSDictionary *)queryString {
    return [self initWithURLString:url queryString:queryString useDefault:YES];
}

- (instancetype)initWithURLString:(NSString *)url queryString:(NSDictionary *)queryString useDefault:(BOOL)useDefault {
    if (self = [super initWithURLString:[[self class] getUrl:url useDefault:useDefault] queryString:queryString]) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
	_hubs = [[NSMutableDictionary alloc] init];
	_callbacks = [[NSMutableDictionary alloc] init];
}

- (id <SRHubProxyInterface>)createHubProxy:(NSString *)hubName {
    if (self.state != disconnected) {
        [NSException raise:NSInternalInconsistencyException format:NSLocalizedString(@"Proxies cannot be added after the connection has been started.",@"NSInternalInconsistencyException")];
    }
    
    SRLogConnectionDebug(@"will create proxy %@",hubName);

    SRHubProxy *hubProxy;
    if(_hubs[[hubName lowercaseString]] == nil) {
        hubProxy = [[SRHubProxy alloc] initWithConnection:self hubName:[hubName lowercaseString]];
        _hubs[[hubName lowercaseString]] = hubProxy;
    }
    return hubProxy;
}

- (NSString *)registerCallback:(SRHubConnectionHubResultBlock)callback {
    NSString *newId = [[NSNumber numberWithInt:_callbackId] stringValue];
    _callbacks[newId] = callback;
    _callbackId += 1;
    return newId;
}

- (void)removeCallback:(NSString *)callbackId {
    [[self callbacks] removeObjectForKey:callbackId];
}

- (void)clearInvocationCallbacks:(NSString *)error {
    SRHubResult *result = [[SRHubResult alloc] init];
    [result setError:error];
    
    for (SRHubConnectionHubResultBlock callback in [self.callbacks allValues]) {
        callback(result);
    }
    
    [self.callbacks removeAllObjects];
}

#pragma mark -
#pragma mark Private

+ (NSString *)getUrl:(NSString *)URL useDefault:(BOOL)useDefault {
    if([URL hasSuffix:@"/"] == false) {
        URL = [URL stringByAppendingString:@"/"];
    }
    
    if(useDefault) {
        return [URL stringByAppendingString:@"signalr"];
    }
    
    return URL;
}

#pragma mark - 
#pragma mark Sending data

- (NSString *)onSending {
    
    NSMutableArray *data = [[NSMutableArray alloc] init];
    for(id key in _hubs) {
        SRHubRegistrationData *registration = [[SRHubRegistrationData alloc] init];
        registration.name = key;
        [data addObject:registration];
    }
        
    return [data SRJSONRepresentation];
}

#pragma mark - 
#pragma mark Received Data

- (void)didReceiveData:(id)data {
    if([data isKindOfClass:[NSDictionary class]]) {
        if ([data valueForKey:@"I"]) {
            SRHubResult *result = [[SRHubResult alloc] initWithDictionary:data];
            SRHubConnectionHubResultBlock callback = _callbacks[result.id];
            if (callback) {
                [_callbacks removeObjectForKey:result.id];
                callback(result);
            }
        } else {
            SRHubInvocation *invocation = [[SRHubInvocation alloc] initWithDictionary:data];
            SRHubProxy *hubProxy = _hubs[[invocation.hub lowercaseString]];
            if(hubProxy) {
                if(invocation.state != nil && ![invocation.state isKindOfClass:[NSNull class]]) {
                    for (id key in invocation.state) {
                        [[hubProxy state] setValue:(invocation.state)[key] forKey:key];
                    }
                }
                [hubProxy invokeEvent:invocation.method withArgs:invocation.args];
            }
            
            [super didReceiveData:data];
        }
    }
}

- (void)willReconnect {
    [self clearInvocationCallbacks:@"Connection started reconnecting before invocation result was received."];
    [super willReconnect];
}

- (void)didClose {
    [self clearInvocationCallbacks:@"Connection was disconnected before invocation result was received."];
    [super didClose];
}

@end
