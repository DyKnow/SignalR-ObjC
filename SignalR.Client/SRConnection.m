//
//  SRConnection.m
//  SignalR
//
//  Created by Alex Billingsley on 10/17/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#include <TargetConditionals.h>
#import "SRConnection.h"
#import "SRSignalRConfig.h"

#import "AFNetworking.h"
#import "NSObject+SRJSON.h"
#import "SRHttpHelper.h"
#import "SRAutoTransport.h"
#import "SRNegotiationResponse.h"
#import "SRVersion.h"
#import "NSDictionary+QueryString.h"

void (^prepareRequest)(id);

@interface SRConnection ()

@property (strong, nonatomic, readonly) NSString *assemblyVersion;
@property (strong, nonatomic, readonly) id <SRClientTransport> transport;

- (void)verifyProtocolVersion:(NSString *)versionString;

@end

#define kNegotiateRequest @"negotiate"

@implementation SRConnection

//private
@synthesize assemblyVersion = _assemblyVersion;
@synthesize transport = _transport;
@synthesize initialized = _initialized;

//public
@synthesize started = _started;
@synthesize received = _received;
@synthesize error = _error;
@synthesize closed = _closed;
@synthesize reconnected = _reconnected;
@synthesize groups = _groups;
@synthesize credentials = _credentials;
@synthesize sending = _sending;
@synthesize url = _url;
@synthesize active = _active;
@synthesize messageId = _messageId;
@synthesize connectionId = _connectionId;
@synthesize items = _items;
@synthesize queryString = _queryString;
@synthesize headers = _headers;

@synthesize delegate = _delegate;

#pragma mark - 
#pragma mark Initialization

+ (SRConnection *)connectionWithURL:(NSString *)url
{
    return [[SRConnection alloc] initWithURL:url];
}

+ (SRConnection *)connectionWithURL:(NSString *)url query:(NSDictionary *)queryString
{
    return [[SRConnection alloc] initWithURL:url queryString:[queryString stringWithFormEncodedComponents]];
}

+ (SRConnection *)connectionWithURL:(NSString *)url queryString:(NSString *)queryString
{
    return [[SRConnection alloc] initWithURL:url queryString:queryString];
}

- (id)initWithURL:(NSString *)url
{
    return [self initWithURL:url queryString:@""];
}

- (id)initWithURL:(NSString *)url query:(NSDictionary *)queryString
{
    return [self initWithURL:url queryString:[queryString stringWithFormEncodedComponents]];
}

- (id)initWithURL:(NSString *)url queryString:(NSString *)queryString
{
    if ((self = [super init])) 
    {
        NSRange range = [queryString rangeOfString:@"?" options:NSCaseInsensitiveSearch];
        if(range.location != NSNotFound) 
        {
            [NSException raise:@"ArgumentException" format:@"Url cannot contain QueryString directly. Pass QueryString values in using available overload."];
        }
        
        if([url hasSuffix:@"/"] == false){
            url = [url stringByAppendingString:@"/"];
        }
        
        _url = url;
        _queryString = queryString;
        _groups = [[NSMutableArray alloc] init];
        _items = [NSMutableDictionary dictionary];
        _headers = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - 
#pragma mark Connection management

- (void)start
{
    // Pick the best transport supported by the client
    [self start:[[SRAutoTransport alloc] init]];
}

- (void)start:(id <SRClientTransport>)transport
{
    if (self.isActive)
    {
        return;
    }
    
    _active = YES;
        
    _transport = transport;
    
    [self negotiate];
}

- (void)negotiate
{
    NSString *data = nil;
    
    if(_sending != nil)
    {
        data = self.sending();
    }
    
    NSString *negotiateUrl = [_url stringByAppendingString:kNegotiateRequest];
    
#if DEBUG_CONNECTION
    SR_DEBUG_LOG(@"[CONNECTION] will negotiate");
#endif
    
    [SRHttpHelper postAsync:negotiateUrl requestPreparer:^(id request)
    {
        if([request isKindOfClass:[NSMutableURLRequest class]])
        {
            [request setTimeoutInterval:30];
        }
        [self prepareRequest:request];
    }
    continueWith:^(id response)
    {
#if DEBUG_CONNECTION
        SR_DEBUG_LOG(@"[CONNECTION] negotiation did receive response %@",response);
#endif
        if([response isKindOfClass:[NSString class]])
        {        
            SRNegotiationResponse *negotiationResponse = [[SRNegotiationResponse alloc] initWithDictionary:[response SRJSONValue]];
#if DEBUG_CONNECTION
            SR_DEBUG_LOG(@"[CONNECTION] negotiation was successful %@",negotiationResponse);
#endif
            [self verifyProtocolVersion:negotiationResponse.protocolVersion];
            
            if(negotiationResponse.connectionId)
            {
                _connectionId = negotiationResponse.connectionId;
                
                [_transport start:self withData:data continueWith:
                 ^(id task) 
                 {
                     _initialized = YES;
                      
                     if(_started != nil)
                     {
                         self.started();
                     }
                     if(_delegate && [_delegate respondsToSelector:@selector(SRConnectionDidOpen:)]){
                         [self.delegate SRConnectionDidOpen:self];
                     }
                 }];
            }
        }
        else if([response isKindOfClass:[NSError class]])
        {
#if DEBUG_CONNECTION
            SR_DEBUG_LOG(@"[CONNECTION] negotiation failed %@",response);
#endif
            [self didReceiveError:response];
        }
    }];
}

- (void)verifyProtocolVersion:(NSString *)versionString
{
    SRVersion *version = nil;
    if((versionString == nil || [versionString isEqualToString:@""] == YES) ||
       ![SRVersion tryParse:versionString forVersion:&version] ||
       !(version.major == 1 && version.minor == 0))
    {
        [NSException raise:@"InvalidOperationException" format:@"Incompatible Protocol Version"];
    }
}

- (void)stop
{
    // Do nothing if the connection was never started
    if (!_initialized)
    {
        return;
    }
    
    @try 
    {
        [_transport stop:self];
        
        if(_closed != nil)
        {
            self.closed();
        }
    }
    @finally 
    {
        if (_delegate && [_delegate respondsToSelector:@selector(SRConnectionDidClose:)]) 
        {
            [self.delegate SRConnectionDidClose:self];
        }
        
        _active = NO;
        _initialized = NO;
    }
}

#pragma mark - 
#pragma mark Sending data

- (void)send:(NSString *)message
{
    [self send:message continueWith:nil];
}

- (void)send:(NSString *)message continueWith:(void (^)(id response))block
{
    if (!_initialized)
    {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:[NSString stringWithFormat:@"InvalidOperationException"] forKey:NSLocalizedFailureReasonErrorKey];
        [userInfo setObject:[NSString stringWithFormat:@"Start must be called before data can be sent"] forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:@"com.SignalR-ObjC.%@",NSStringFromClass([self class])] 
                                             code:0 
                                         userInfo:userInfo];
        [self didReceiveError:error];
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


- (void) setHeader:(NSString *)header toValue:(NSString *)value
{
    [_headers setValue:value forKey:header];
}

#pragma mark - 
#pragma mark Prepare Request

- (void)prepareRequest:(id)request
{
    if([request isKindOfClass:[NSMutableURLRequest class]])
    {
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
        [request addValue:[self createUserAgentString:@"SignalR.Client.iOS"] forHTTPHeaderField:@"User-Agent"];
#elif TARGET_OS_MAC
        [request addValue:[self createUserAgentString:@"SignalR.Client.OSX"] forHTTPHeaderField:@"User-Agent"];
#endif
        if(_credentials != nil)
        {
            // Create a AFHTTPClient for the sole purpose of generating an authorization header.
            AFHTTPClient *clientForAuthHeader = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
            [clientForAuthHeader setAuthorizationHeaderWithUsername:_credentials.user password:_credentials.password];
            
            //Set the Authorization header that we just generated to our actual request
            [request addValue:[clientForAuthHeader defaultValueForHeader:@"Authorization"] forHTTPHeaderField:@"Authorization"];
        }
        for(NSString *header in _headers) 
        {
            [request addValue:[_headers valueForKey:header] forHTTPHeaderField:header];
        }
    }
}

- (NSString *)createUserAgentString:(NSString *)client
{
    if(_assemblyVersion == nil)
    {
        //Need to manually set this otherwise it will inherit from the project version
        _assemblyVersion = @"0.4";
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
    //private
    _assemblyVersion = nil;
    _transport = nil;
    _initialized = NO;
    _started = nil;
    _received = nil;
    _error = nil;
    _closed = nil;
    _groups = nil;
    _credentials = nil;
    _sending = nil;
    _url = nil;
    _active = NO;
    _messageId = nil;
    _connectionId = nil;
    _items = nil;
    _queryString = nil;
    _delegate = nil;
}

@end
