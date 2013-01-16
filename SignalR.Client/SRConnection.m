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
#import "SRDefaultHttpClient.h"
#import "SRLog.h"
#import "SRNegotiationResponse.h"
#import "SRVersion.h"

#import "NSObject+SRJSON.h"

void (^prepareRequest)(id);

@interface SRConnection ()

@property (strong, nonatomic, readonly) SRVersion *assemblyVersion;
@property (strong, nonatomic, readonly) id <SRClientTransport> transport;
@property (strong, nonatomic, readwrite) NSNumber * disconnectTimeout;

@property (assign, nonatomic, readwrite) connectionState state;
@property (strong, nonatomic, readwrite) NSString *url;
@property (strong, nonatomic, readwrite) NSMutableDictionary *items;
@property (strong, nonatomic, readwrite) NSString *queryString;

- (void)negotiate:(id <SRClientTransport>)transport;
- (void)verifyProtocolVersion:(NSString *)versionString;
- (NSString *)createQueryString:(NSDictionary *)queryString;

@end

@implementation SRConnection

#pragma mark - 
#pragma mark Initialization

+ (id)connectionWithURL:(NSString *)url {
    return [[[self class] alloc] initWithURLString:url];
}

+ (id)connectionWithURL:(NSString *)url query:(NSDictionary *)queryString {
    return [[[self class] alloc] initWithURLString:url query:queryString];
}

+ (id)connectionWithURL:(NSString *)url queryString:(NSString *)queryString {
    return [[[self class] alloc] initWithURLString:url queryString:queryString];
}

- (id)initWithURLString:(NSString *)url {
    return [self initWithURLString:url queryString:@""];
}

- (id)initWithURLString:(NSString *)url query:(NSDictionary *)queryString {
    return [self initWithURLString:url queryString:[self createQueryString:queryString]];
}

- (id)initWithURLString:(NSString *)url queryString:(NSString *)queryString {
    if (self = [super init]) {
        
        if (url == nil) {
            [NSException raise:NSInvalidArgumentException format:NSLocalizedString(@"Url should be non-null",@"")];
        }
        
        if([queryString rangeOfString:@"?" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [NSException raise:NSInvalidArgumentException format:NSLocalizedString(@"Url cannot contain query string directly. Pass query string values in using available overload.",@"")];
        }
        
        if([url hasSuffix:@"/"] == false) {
            url = [url stringByAppendingString:@"/"];
        }
        
        _url = url;
        _queryString = queryString;
        _groups = [NSMutableArray array];
        _items = [NSMutableDictionary dictionary];
        _headers = [NSMutableDictionary dictionary];
        _state = disconnected;
    }
    return self;
}

#pragma mark - 
#pragma mark Connection management

- (void)start {
    [self startHttpClient:[[SRDefaultHttpClient alloc] init]];
}

- (void)startHttpClient:(id <SRHttpClient>)httpClient {
    // Pick the best transport supported by the client
    [self start:[[SRAutoTransport alloc] initWithHttpClient:httpClient]];
}

- (void)start:(id <SRClientTransport>)transport {
    if (![self changeState:disconnected toState:connecting]) {
        return;
    }
            
    _transport = transport;
    
    [self negotiate:transport];
}

- (void)negotiate:(id<SRClientTransport>)transport {
    SRLogConnection(@"will negotiate");
    
    [transport negotiate:self continueWith:^(SRNegotiationResponse *negotiationResponse) {
        SRLogConnection(@"negotiation was successful %@",negotiationResponse);

        [self verifyProtocolVersion:negotiationResponse.protocolVersion];
        
        if(negotiationResponse.connectionId) {
            _connectionId = negotiationResponse.connectionId;
            _disconnectTimeout = negotiationResponse.disconnectTimeout;
            
            NSString *data = [self onSending];
            
            [_transport start:self withData:data continueWith:^(id task) {
                [self changeState:connecting toState:connected];
                
                if(self.started != nil) {
                    self.started();
                }
                if(self.delegate && [self.delegate respondsToSelector:@selector(SRConnectionDidOpen:)]) {
                    [self.delegate SRConnectionDidOpen:self];
                }
            }];
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
       !(version.major == 1 && version.minor == 1)) {
        [NSException raise:NSInternalInconsistencyException format:NSLocalizedString(@"Incompatible Protocol Version",@"NSInternalInconsistencyException")];
    }
}

- (void)stop {
    // Do nothing if the connection is offline
    if (self.state != disconnected) {
        [_transport abort:self];
        [self disconnect];
    }
}

- (void)disconnect {
    if (self.state != disconnected) {
        
        #warning nullify disconnect timeout operation here
        
        _state = disconnected;
        
        if(_closed != nil) {
            self.closed();
        }
        
        if (_delegate && [_delegate respondsToSelector:@selector(SRConnectionDidClose:)]) {
            [self.delegate SRConnectionDidClose:self];
        }
    }
}

#pragma mark -
#pragma mark Sending data

- (NSString *)onSending {
    return nil;
}

- (void)send:(id)object {
    [self send:object continueWith:nil];
}

- (void)send:(id)object continueWith:(void (^)(id response))block {
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
    [_transport send:self withData:message continueWith:block];
}

#pragma mark - 
#pragma mark Received Data

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
#warning TODO: start disconnect timeout operation here.
    if (self.reconnecting != nil) {
        self.reconnecting();
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(SRConnectionWillReconnect:)]) {
        [self.delegate SRConnectionWillReconnect:self];
    }
}

- (void)didReconnect {
#warning nullify disconnect timeout operation here
    if(self.reconnected != nil) {
        self.reconnected();
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(SRConnectionDidReconnect:)]) {
        [self.delegate SRConnectionDidReconnect:self];
    }
}

- (void)addValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    [_headers setValue:value forKey:field];
}

#pragma mark - 
#pragma mark Prepare Request

- (void)prepareRequest:(id <SRRequest>)request {
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    [request setUserAgent:[self createUserAgentString:NSLocalizedString(@"SignalR.Client.iOS",@"")]];
#elif TARGET_OS_MAC
    [request setUserAgent:[self createUserAgentString:NSLocalizedString(@"SignalR.Client.OSX",@"")]];
#endif
    
    [request setCredentials:_credentials];
    
    [request setHeaders:_headers];
    
    //TODO: Potentially set proxy here
}

- (NSString *)createUserAgentString:(NSString *)client {
    if(_assemblyVersion == nil) {
        _assemblyVersion = [[SRVersion alloc] initWithMajor:1 minor:0 build:0 revision:2];
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

//TODO: Consider Moving to a Category
- (BOOL)ensureReconnecting {
    if ([self changeState:connected toState:reconnecting]) {
        [self willReconnect];
    }
    return (self.state == reconnecting);
}

- (void)dealloc {
    _assemblyVersion = nil;
    _transport = nil;
    _started = nil;
    _received = nil;
    _error = nil;
    _closed = nil;
    _groups = nil;
    _credentials = nil;
    _url = nil;
    _messageId = nil;
    _connectionId = nil;
    _items = nil;
    _queryString = nil;
    _headers = nil;
    _delegate = nil;
}

@end
