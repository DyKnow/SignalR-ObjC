//
//  SRConnection.m
//  SignalR
//
//  Created by Alex Billingsley on 10/17/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "SRConnection.h"

#import "SBJson.h"
#import "SRHttpHelper.h"
#import "ASIHTTPRequest.h"
#import "SRTransport.h"
#import "SRNegotiationResponse.h"
#import "SRVersion.h"

void (^prepareRequest)(ASIHTTPRequest *);

@interface SRConnection ()

@property (strong, nonatomic, readonly) NSString *assemblyVersion;
@property (strong, nonatomic, readonly) id <SRClientTransport> transport;
@property (assign, nonatomic, readonly) BOOL initialized;

- (void)verifyProtocolVersion:(NSString *)versionString;

@end

#define kNegotiateRequest @"negotiate"

@implementation SRConnection

//private
@synthesize assemblyVersion = _assemblyVersion;
@synthesize transport = _transport;
@synthesize initialized = _initialized;

//public
@synthesize received = _received;
@synthesize error = _error;
@synthesize closed = _closed;
@synthesize groups = _groups;
@synthesize sending = _sending;
@synthesize url = _url;
@synthesize active = _active;
@synthesize messageId = _messageId;
@synthesize connectionId = _connectionId;
@synthesize items = _items;

@synthesize delegate = _delegate;

#pragma mark - 
#pragma mark Initialization

+ (SRConnection *)connectionWithURL:(NSString *)URL
{
    return [[SRConnection alloc] initWithURL:URL];
}

- (id)initWithURL:(NSString *)URL
{
    if ((self = [super init])) {
        if([URL hasSuffix:@"/"] == false){
            URL = [URL stringByAppendingString:@"/"];
        }
        
        _url = URL;
        _groups = [[NSMutableArray alloc] init];
        _items = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - 
#pragma mark Connection management

- (void)start
{
    [self start:[SRTransport LongPolling]];
}

- (void)start:(id <SRClientTransport>)transport
{
    if (self.isActive)
    {
        return;
    }
    
    _active = YES;
        
    _transport = transport;
    
    NSString *data = nil;
    
    if(_sending != nil)
    {
        data = self.sending();
    }
    
    NSString *negotiateUrl = [_url stringByAppendingString:kNegotiateRequest];

    [SRHttpHelper postAsync:negotiateUrl requestPreparer:^(ASIHTTPRequest * request)
    {
        [self prepareRequest:request];
    }
    continueWith:^(id response) 
    {
        if([response isKindOfClass:[NSString class]])
        {        
            SRNegotiationResponse *negotiationResponse = [[SRNegotiationResponse alloc] initWithDictionary:[[SBJsonParser new] objectWithString:response]];
#if DEBUG
            NSLog(@"%@",negotiationResponse);
#endif
            [self verifyProtocolVersion:negotiationResponse.protocolVersion];
            
            if(negotiationResponse.connectionId){
                _connectionId = negotiationResponse.connectionId;
                
                [_transport start:self withData:data];
                
                _initialized = YES;
                
                if(_delegate && [_delegate respondsToSelector:@selector(SRConnectionDidOpen:)]){
                    [self.delegate SRConnectionDidOpen:self];
                }
            }
        }
        else if([response isKindOfClass:[NSError class]])
        {
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
    [self send:message onCompletion:nil];
}

- (void)send:(NSString *)message onCompletion:(void(^)(id))block
{
    if (!_initialized)
    {
        [NSException raise:@"InvalidOperationException" format:@"Start must be called before data can be sent"];
    }

    [_transport send:self withData:message onCompletion:block];
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

#pragma mark - 
#pragma mark Prepare Request
//TODO:Handle Credentials
- (void)prepareRequest:(ASIHTTPRequest *)request
{
#if TARGET_IPHONE || TARGET_IPHONE_SIMULATOR
    [request addRequestHeader:@"User-Agent" value:[self createUserAgentString:@"SignalR.Client.iOS"]];
#elif TARGET_OS_MAC
    [request addRequestHeader:@"User-Agent" value:[self createUserAgentString:@"SignalR.Client.MAC"]];
#endif

    //Handle Credentials
    //if(_credentials != nil)
    //{
    //  request.credentials = _credentials;
    //}
}

//TODO: Include system version, causes issues in framework bundle
- (NSString *)createUserAgentString:(NSString *)client
{
    if(_assemblyVersion == nil)
    {
        _assemblyVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    }
#if TARGET_IPHONE || TARGET_IPHONE_SIMULATOR
    return [NSString stringWithFormat:@"%@/%@",client,_assemblyVersion];
    //return [NSString stringWithFormat:@"%@/%@ (%@ %@)",client,_assemblyVersion,[[UIDevice currentDevice] localizedModel],[[UIDevice currentDevice] systemVersion]];
#elif TARGET_OS_MAC
    //TODO: Add system version
    return [NSString stringWithFormat:@"%@/%@",client,_assemblyVersion];
#endif
}

- (void)dealloc
{
    _delegate = nil;
}

@end
