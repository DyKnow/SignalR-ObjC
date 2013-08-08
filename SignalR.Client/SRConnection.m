//
//  SRConnection.m
//  SignalR
//
//  Created by Alex Billingsley on 10/17/11.
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

#include <TargetConditionals.h>
#import "SRAutoTransport.h"
#import "SRConnection.h"
#import "SRLog.h"
#import "SRNegotiationResponse.h"
#import "SRVersion.h"
#import "SRKeepAliveData.h"
#import "SRHeartbeatMonitor.h"

#import "NSObject+SRJSON.h"

void (^prepareRequest)(id);

@interface SRConnection ()

@property (strong, nonatomic, readwrite) NSNumber * defaultAbortTimeout;
@property (strong, nonatomic, readonly) SRVersion *assemblyVersion;
@property (strong, nonatomic, readwrite) NSNumber * disconnectTimeout;
@property (strong, nonatomic, readwrite) NSBlockOperation * disconnectTimeoutOperation;

@property (assign, nonatomic, readwrite) connectionState state;
@property (strong, nonatomic, readwrite) NSString *url;
@property (strong, nonatomic, readwrite) NSMutableDictionary *items;
@property (strong, nonatomic, readwrite) NSString *queryString;
@property (strong, nonatomic, readwrite) SRHeartbeatMonitor *monitor;

- (void)negotiate:(id <SRClientTransportInterface>)transport;
- (void)verifyProtocolVersion:(NSString *)versionString;
- (NSString *)createQueryString:(NSDictionary *)queryString;
- (NSString *)createUserAgentString:(NSString *)client;

@end

@implementation SRConnection

@synthesize keepAliveData = _keepAliveData;
@synthesize messageId = _messageId;
@synthesize groupsToken = _groupsToken;
@synthesize connectionToken = _connectionToken;
@synthesize items = _items;
@synthesize connectionId = _connectionId;
@synthesize url = _url;
@synthesize queryString = _queryString;
@synthesize state = _state;
@synthesize transport = _transport;
@synthesize credentials = _credentials;
@synthesize headers = _headers;

#pragma mark - 
#pragma mark Initialization

+ (instancetype)connectionWithURL:(NSString *)url {
    return [[[self class] alloc] initWithURLString:url];
}

+ (instancetype)connectionWithURL:(NSString *)url query:(NSDictionary *)queryString {
    return [[[self class] alloc] initWithURLString:url query:queryString];
}

+ (instancetype)connectionWithURL:(NSString *)url queryString:(NSString *)queryString {
    return [[[self class] alloc] initWithURLString:url queryString:queryString];
}

- (instancetype)initWithURLString:(NSString *)url {
    return [self initWithURLString:url queryString:nil];
}

- (instancetype)initWithURLString:(NSString *)url query:(NSDictionary *)queryString {
    return [self initWithURLString:url queryString:[self createQueryString:queryString]];
}

- (instancetype)initWithURLString:(NSString *)url queryString:(NSString *)queryString {
    if (self = [super init]) {
        if (url == nil) {
            [NSException raise:NSInvalidArgumentException format:NSLocalizedString(@"Url should be non-null",@"")];
        }
        
        if(queryString && [queryString rangeOfString:@"?" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [NSException raise:NSInvalidArgumentException format:NSLocalizedString(@"Url cannot contain query string directly. Pass query string values in using available overload.",@"")];
        }
        
        if([url hasSuffix:@"/"] == NO) {
            url = [url stringByAppendingString:@"/"];
        }
        
        _url = url;
        _queryString = queryString;
        _items = [NSMutableDictionary dictionary];
        _headers = [NSMutableDictionary dictionary];
        _state = disconnected;
        _defaultAbortTimeout = @30;
    }
    return self;
}

#pragma mark - 
#pragma mark Connection management

- (void)start {
    // Pick the best transport supported by the client
    [self start:[[SRAutoTransport alloc] init]];
}

- (void)start:(id <SRClientTransportInterface>)transport {
    if (![self changeState:disconnected toState:connecting]) {
        return;
    }
    
    _monitor = [[SRHeartbeatMonitor alloc] initWithConnection:self];
    _transport = transport;
    
    [self negotiate:transport];
}

- (void)negotiate:(id<SRClientTransportInterface>)transport {
    SRLogConnection(@"will negotiate");
    
    __weak __typeof(&*self)weakSelf = self;
    [transport negotiate:self completionHandler:^(SRNegotiationResponse *negotiationResponse) {
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        SRLogConnection(@"negotiation was successful %@",negotiationResponse);

        [strongSelf verifyProtocolVersion:negotiationResponse.protocolVersion];
        
        _connectionId = negotiationResponse.connectionId;
        _connectionToken = negotiationResponse.connectionToken;
        _disconnectTimeout = negotiationResponse.disconnectTimeout;
        
        // If we have a keep alive
        if (negotiationResponse.keepAliveTimeout != nil) {
            _keepAliveData = [[SRKeepAliveData alloc] initWithTimeout:negotiationResponse.keepAliveTimeout];
        }
        
        NSString *data = [strongSelf onSending];
        [strongSelf startTransport:data];
    }];
}

- (void)startTransport:(NSString *)data {
    __weak __typeof(&*self)weakSelf = self;
    [self.transport start:self data:data completionHandler:^(id task) {
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        
        [strongSelf changeState:connecting toState:connected];
        
        if (_keepAliveData != nil) {
            [_monitor start];
        }
        
        if(strongSelf.started != nil) {
            strongSelf.started();
        }
        if(strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(SRConnectionDidOpen:)]) {
            [strongSelf.delegate SRConnectionDidOpen:strongSelf];
        }
    }];
}

- (BOOL)changeState:(connectionState)oldState toState:(connectionState)newState {
    @synchronized(self) {
        // If we're in the expected old state then change state and return true
        if (self.state == oldState) {
            self.state = newState;
            
            if (self.stateChanged){
                self.stateChanged(self.state);
            }
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(SRConnection:didChangeState:newState:)]) {
                [self.delegate SRConnection:self didChangeState:oldState newState:newState];
            }
            return YES;
        }
        
        // Invalid transition
        return NO;
    }
}

- (void)verifyProtocolVersion:(NSString *)versionString {
    SRVersion *version = nil;
    if((versionString == nil || [versionString isEqualToString:@""] == YES) ||
       ![SRVersion tryParse:versionString forVersion:&version] ||
       !(version.major == 1 && version.minor == 2)) {
        [NSException raise:NSInternalInconsistencyException format:NSLocalizedString(@"Incompatible Protocol Version",@"NSInternalInconsistencyException")];
    }
}

- (void)stop {
    [self stop:self.defaultAbortTimeout];
}

- (void)stop:(NSNumber *)timeout {
    
    //TODO: Handle Timeout HERE
    
    // Do nothing if the connection is offline
    if (self.state != disconnected) {
        
        [_monitor stop];
        _monitor = nil;
        
        [_transport abort:self timeout:timeout];
        [self disconnect];
        
        _transport = nil;
    }
}

- (void)disconnect {
    if (self.state != disconnected) {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:SRConnectionDidDisconnect object:self];
        
        _state = disconnected;
        
        [_monitor stop];
        _monitor = nil;
        
        // Clear the state for this connection
        _connectionId = nil;
        _connectionToken = nil;
        _groupsToken = nil;
        _messageId = nil;
        
        [self didClose];
    }
}

#pragma mark -
#pragma mark Sending data

- (NSString *)onSending {
    return nil;
}

- (void)send:(id)object {
    [self send:object completionHandler:nil];
}

- (void)send:(id)object completionHandler:(void (^)(id response))block {
    if (self.state == disconnected) {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        userInfo[NSLocalizedFailureReasonErrorKey] = NSInternalInconsistencyException;
        userInfo[NSLocalizedDescriptionKey] = [NSString stringWithFormat:NSLocalizedString(@"Start must be called before data can be sent",@"NSInternalInconsistencyException")];
        NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:NSLocalizedString(@"com.SignalR-ObjC.%@",@""),NSStringFromClass([self class])] 
                                             code:0 
                                         userInfo:userInfo];
        [self didReceiveError:error];
    }
    
    if (self.state == connecting) {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        userInfo[NSLocalizedFailureReasonErrorKey] = NSInternalInconsistencyException;
        userInfo[NSLocalizedDescriptionKey] = [NSString stringWithFormat:NSLocalizedString(@"The connection has not been established",@"NSInternalInconsistencyException")];
        NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:NSLocalizedString(@"com.SignalR-ObjC.%@",@""),NSStringFromClass([self class])] 
                                             code:0 
                                         userInfo:userInfo];
        [self didReceiveError:error];
    }

    NSString *message = nil;
    if ([object isKindOfClass:[NSString class]]) {
        message = object;
    } else {
        message = [object SRJSONRepresentation];
    }
    [self.transport send:self data:message completionHandler:block];
}

#pragma mark - 
#pragma mark Received Data

#warning TODO: Change type to id or NSDictionary (This is a JSON object)
- (void)didReceiveData:(NSString *)message {
    if(self.received != nil) {
        self.received(message);
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(SRConnection:didReceiveData:)]) {
        [self.delegate SRConnection:self didReceiveData:message];
    }
}

- (void)didReceiveError:(NSError *)ex {
    if(self.error != nil) {
        self.error(ex);
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(SRConnection:didReceiveError:)]) {
        [self.delegate SRConnection:self didReceiveError:ex];
    }
}

- (void)willReconnect {
    
    // Only allow the client to attempt to reconnect for a _disconnectTimout TimeSpan which is set by
    // the server during negotiation.
    // If the client tries to reconnect for longer the server will likely have deleted its ConnectionId
    // topic along with the contained disconnect message.
    __weak __typeof(&*self)weakSelf = self;
    self.disconnectTimeoutOperation = [NSBlockOperation blockOperationWithBlock:^{
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        [strongSelf disconnect];
    }];
    [self.disconnectTimeoutOperation performSelector:@selector(start) withObject:nil afterDelay:[_disconnectTimeout integerValue]];
    
    if (self.reconnecting != nil) {
        self.reconnecting();
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(SRConnectionWillReconnect:)]) {
        [self.delegate SRConnectionWillReconnect:self];
    }
}

- (void)didReconnect {
    [NSObject cancelPreviousPerformRequestsWithTarget:self.disconnectTimeoutOperation
                                             selector:@selector(start)
                                               object:nil];
    self.disconnectTimeoutOperation = nil;
    
    if(self.reconnected != nil) {
        self.reconnected();
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(SRConnectionDidReconnect:)]) {
        [self.delegate SRConnectionDidReconnect:self];
    }
    
    [self updateLastKeepAlive];
}

- (void)connectionDidSlow {
    if (self.connectionSlow != nil) {
        self.connectionSlow();
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(SRConnectionDidSlow:)]) {
        [self.delegate SRConnectionDidSlow:self];
    }
}

- (void)didClose {
    if (self.closed != nil) {
        self.closed();
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(SRConnectionDidClose:)]) {
        [self.delegate SRConnectionDidClose:self];
    }
}

#pragma mark -
#pragma mark Prepare Request

- (void)addValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    [_headers setValue:value forKey:field];
}

- (void)updateLastKeepAlive {
    if (_keepAliveData != nil) {
        _keepAliveData.lastKeepAlive = [NSDate date];
    }
}

- (void)prepareRequest:(NSMutableURLRequest *)request {
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    [request addValue:[self createUserAgentString:NSLocalizedString(@"SignalR.Client.iOS",@"")] forHTTPHeaderField:@"User-Agent"];
#elif TARGET_OS_MAC
    [request addValue:[self createUserAgentString:NSLocalizedString(@"SignalR.Client.OSX",@"")] forHTTPHeaderField:@"User-Agent"];
#endif
    
    //TODO: set credentials
    //[request setCredentials:_credentials];
    
    [request setAllHTTPHeaderFields:_headers];
    
    //TODO: Potentially set proxy here
}

- (NSString *)createUserAgentString:(NSString *)client {
    if(_assemblyVersion == nil) {
        _assemblyVersion = [[SRVersion alloc] initWithMajor:1 minor:3 build:0 revision:0];
    }
   
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    return [NSString stringWithFormat:@"%@/%@ (%@ %@)",client,_assemblyVersion,[[UIDevice currentDevice] localizedModel],[[UIDevice currentDevice] systemVersion]];
#elif TARGET_OS_MAC
    NSString *environmentVersion = @"";
    if([[NSProcessInfo processInfo] operatingSystem] == NSMACHOperatingSystem) {
        environmentVersion = [environmentVersion stringByAppendingString:@"Mac OS X"];
        NSString *version = [[NSProcessInfo processInfo] operatingSystemVersionString];        
        if ([version rangeOfString:@"Version"].location != NSNotFound) {
            environmentVersion = [environmentVersion stringByAppendingFormat:@" %@",version];
        }
        return [NSString stringWithFormat:@"%@/%@ (%@)",client,_assemblyVersion,environmentVersion];
    }
    return [NSString stringWithFormat:@"%@/%@",client,_assemblyVersion];
#endif
}

- (NSString *)createQueryString:(NSDictionary *)queryString {
    NSMutableArray *components = [NSMutableArray array];
    for (NSString *key in [queryString allKeys]) {
        [components addObject:[NSString stringWithFormat:@"%@=%@",key,queryString[key]]];
    }

    return [components componentsJoinedByString:@"&"];
}

@end

NSString * const SRConnectionDidDisconnect = @"SRConnectionDidDisconnect";
