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
#import "SRNegotiationResponse.h"
#import "SRSignalRConfig.h"
#import "SRVersion.h"

#import "NSDictionary+QueryString.h"
#import "NSObject+SRJSON.h"

void (^prepareRequest)(id);

@interface SRConnection ()

@property (strong, nonatomic, readonly) SRVersion *assemblyVersion;
@property (strong, nonatomic, readonly) id <SRClientTransport> transport;

- (void)verifyProtocolVersion:(NSString *)versionString;

@end

@implementation SRConnection

//private
@synthesize assemblyVersion = _assemblyVersion;
@synthesize transport = _transport;

//public
@synthesize started = _started;
@synthesize received = _received;
@synthesize error = _error;
@synthesize closed = _closed;
@synthesize reconnected = _reconnected;
@synthesize groups = _groups;
@synthesize credentials = _credentials;
@synthesize url = _url;
@synthesize messageId = _messageId;
@synthesize connectionId = _connectionId;
@synthesize items = _items;
@synthesize queryString = _queryString;
@synthesize state = _state;
@synthesize headers = _headers;

@synthesize delegate = _delegate;

#pragma mark - 
#pragma mark Initialization

+ (id)connectionWithURL:(NSString *)url
{
    return [[[self class] alloc] initWithURLString:url];
}

+ (id)connectionWithURL:(NSString *)url query:(NSDictionary *)queryString
{
    return [[[self class] alloc] initWithURLString:url queryString:[queryString stringWithFormEncodedComponents]];
}

+ (id)connectionWithURL:(NSString *)url queryString:(NSString *)queryString
{
    return [[[self class] alloc] initWithURLString:url queryString:queryString];
}

- (id)initWithURLString:(NSString *)url
{
    return [self initWithURLString:url queryString:@""];
}

- (id)initWithURLString:(NSString *)url query:(NSDictionary *)queryString
{
    return [self initWithURLString:url queryString:[queryString stringWithFormEncodedComponents]];
}

- (id)initWithURLString:(NSString *)url queryString:(NSString *)queryString
{
    if ((self = [super init])) 
    {
        NSRange range = [queryString rangeOfString:@"?" options:NSCaseInsensitiveSearch];
        if(range.location != NSNotFound) 
        {
            [NSException raise:NSInvalidArgumentException format:NSLocalizedString(@"Url cannot contain QueryString directly. Pass QueryString values in using available overload.",@"")];
        }
        
        if([url hasSuffix:@"/"] == false){
            url = [url stringByAppendingString:@"/"];
        }
        
        _url = url;
        _queryString = queryString;
        _groups = [[NSMutableArray alloc] init];
        _items = [NSMutableDictionary dictionary];
        _headers = [NSMutableDictionary dictionary];
        _state = disconnected;
    }
    return self;
}

#pragma mark - 
#pragma mark Connection management

- (void)start
{
    [self startHttpClient:[[SRDefaultHttpClient alloc] init]];
}

- (void)startHttpClient:(id <SRHttpClient>)httpClient
{
    // Pick the best transport supported by the client
    [self start:[[SRAutoTransport alloc] initWithHttpClient:httpClient]];
}

- (void)start:(id <SRClientTransport>)transport
{
    if (![self changeState:disconnected toState:connecting])
    {
        return;
    }
            
    _transport = transport;
    
    [self negotiate:transport];
}

- (void)negotiate:(id<SRClientTransport>)transport
{
#if DEBUG_CONNECTION
    SR_DEBUG_LOG(@"[CONNECTION] will negotiate");
#endif
    
    [transport negotiate:self continueWith:^(SRNegotiationResponse *negotiationResponse) 
    {
#if DEBUG_CONNECTION
        SR_DEBUG_LOG(@"[CONNECTION] negotiation was successful %@",negotiationResponse);
#endif
        [self verifyProtocolVersion:negotiationResponse.protocolVersion];
        
        if(negotiationResponse.connectionId)
        {
            _connectionId = negotiationResponse.connectionId;
            
            NSString *data = [self onSending];
            
            [_transport start:self withData:data continueWith:
             ^(id task) 
            {
                 
                [self changeState:connecting toState:connected];
                
                if(_started != nil)
                {
                    self.started();
                }
                if(_delegate && [_delegate respondsToSelector:@selector(SRConnectionDidOpen:)]){
                    [self.delegate SRConnectionDidOpen:self];
                }
            }];
        }
    }];
}

- (BOOL)changeState:(connectionState)oldState toState:(connectionState)newState
{
    @synchronized(self)
    {
        // If we're in the expected old state then change state and return true
        if (self.state == oldState)
        {
            self.state = newState;
            return YES;
        }
        // Invalid transition
        return NO;
    }
}

- (void)verifyProtocolVersion:(NSString *)versionString
{
    SRVersion *version = nil;
    if((versionString == nil || [versionString isEqualToString:@""] == YES) ||
       ![SRVersion tryParse:versionString forVersion:&version] ||
       !(version.major == 1 && version.minor == 0))
    {
        [NSException raise:NSInternalInconsistencyException format:NSLocalizedString(@"Incompatible Protocol Version",@"NSInternalInconsistencyException")];
    }
}

- (void)stop
{
    @try 
    {
        // Do nothing if the connection is offline
        if (self.state == disconnected)
        {
            return;
        }
        
        [_transport stop:self];
        
        if(_closed != nil)
        {
            self.closed();
        }
        
        if (_delegate && [_delegate respondsToSelector:@selector(SRConnectionDidClose:)]) 
        {
            [self.delegate SRConnectionDidClose:self];
        }
    }
    @finally 
    {
        _state = disconnected;
    }
}

#pragma mark - 
#pragma mark Sending data

- (NSString *)onSending
{
    return nil;
}

- (void)send:(id)object
{
    [self send:object continueWith:nil];
}

- (void)send:(id)object continueWith:(void (^)(id response))block
{
    if (self.state == disconnected)
    {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:NSInternalInconsistencyException forKey:NSLocalizedFailureReasonErrorKey];
        [userInfo setObject:[NSString stringWithFormat:NSLocalizedString(@"Start must be called before data can be sent",@"NSInternalInconsistencyException")] forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:NSLocalizedString(@"com.SignalR-ObjC.%@",@""),NSStringFromClass([self class])] 
                                             code:0 
                                         userInfo:userInfo];
        [self didReceiveError:error];
    }
    
    if (self.state == connecting)
    {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:NSInternalInconsistencyException forKey:NSLocalizedFailureReasonErrorKey];
        [userInfo setObject:[NSString stringWithFormat:NSLocalizedString(@"The connection has not been established",@"NSInternalInconsistencyException")] forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:NSLocalizedString(@"com.SignalR-ObjC.%@",@""),NSStringFromClass([self class])] 
                                             code:0 
                                         userInfo:userInfo];
        [self didReceiveError:error];
    }

    NSString *message = nil;
    if ([object isKindOfClass:[NSString class]])
    {
        message = object;
    }
    else
    {
        message = [object SRJSONRepresentation];
    }
    [_transport send:self withData:message continueWith:block];
}

#pragma mark - 
#pragma mark Received Data

- (void)didReceiveData:(NSString *)message
{
    if(_received != nil)
    {
        self.received(message);
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(SRConnection:didReceiveData:)]) 
    {
        [self.delegate SRConnection:self didReceiveData:message];
    }
}

- (void)didReceiveError:(NSError *)ex
{
    if(_error != nil)
    {
        self.error(ex);
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(SRConnection:didReceiveError:)]) 
    {
        [self.delegate SRConnection:self didReceiveError:ex];
    }
}

- (void)didReconnect
{
    if(_reconnected != nil)
    {
        self.reconnected();
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(SRConnectionDidReconnect:)]) 
    {
        [self.delegate SRConnectionDidReconnect:self];
    }
}

- (void)addValue:(NSString *)value forHTTPHeaderField:(NSString *)field
{
    [_headers setValue:value forKey:field];
}

#pragma mark - 
#pragma mark Prepare Request

- (void)prepareRequest:(id <SRRequest>)request
{
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    [request setUserAgent:[self createUserAgentString:NSLocalizedString(@"SignalR.Client.iOS",@"")]];
#elif TARGET_OS_MAC
    [request setUserAgent:[self createUserAgentString:NSLocalizedString(@"SignalR.Client.OSX",@"")]];
#endif
    
    [request setCredentials:_credentials];
    
    [request setHeaders:_headers];
}

- (NSString *)createUserAgentString:(NSString *)client
{
    if(_assemblyVersion == nil)
    {
        _assemblyVersion = [[SRVersion alloc] initWithMajor:0 minor:5 build:2 revision:0];
    }
   
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    return [NSString stringWithFormat:@"%@/%@ (%@ %@)",client,_assemblyVersion,[[UIDevice currentDevice] localizedModel],[[UIDevice currentDevice] systemVersion]];
#elif TARGET_OS_MAC
    NSString *environmentVersion = @"";
    if([[NSProcessInfo processInfo] operatingSystem] == NSMACHOperatingSystem)
    {
        environmentVersion = [environmentVersion stringByAppendingString:@"Mac OS X"];
        NSString *version = [[NSProcessInfo processInfo] operatingSystemVersionString];        
        if ([version rangeOfString:@"Version"].location != NSNotFound)
        {
            environmentVersion = [environmentVersion stringByAppendingFormat:@" %@",version];
        }
        return [NSString stringWithFormat:@"%@/%@ (%@)",client,_assemblyVersion,environmentVersion];
    }
    return [NSString stringWithFormat:@"%@/%@",client,_assemblyVersion];
#endif
}

- (void)dealloc
{
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
