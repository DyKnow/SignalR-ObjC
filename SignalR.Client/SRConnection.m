//
//  SRConnection.m
//  SignalR
//
//  Created by Alex Billingsley on 10/17/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "SRConnection.h"

#import "SBJson.h"
#import "HttpHelper.h"
#import "SRTransport.h"
#import "SRNegotiationResponse.h"

void (^prepareRequest)(NSMutableURLRequest *);

@interface SRConnection ()

@property (nonatomic, assign) BOOL initialized;

- (void)verifyProtocolVersion:(NSString *)versionString;

@end

#define kNegotiateRequest @"negotiate"

@implementation SRConnection

@synthesize transport = _transport;
@synthesize url;
@synthesize connectionId;
@synthesize messageId;
@synthesize data;
@synthesize active;
@synthesize groups;
@synthesize assemblyVersion = _assemblyVersion;
@synthesize initialized = _initialized;
@synthesize items = _items;

@synthesize sending;
@synthesize received;
@synthesize error;
@synthesize closed;

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
        _transport = [SRTransport LongPolling];
        self.groups = [[NSMutableArray alloc] init];
        _items = [NSMutableDictionary dictionary];
        if([URL hasSuffix:@"/"] == false){
            URL = [URL stringByAppendingString:@"/"];
        }
        self.url = URL;
    }
    return self;
}

#pragma mark - 
#pragma mark Connection management

- (void)start
{
    if (self.isActive)
        return;
    
    active = YES;
    
    self.data = nil;
    
    if(sending != nil)
    {
        self.data = self.sending();
    }
    
    NSString *negotiateUrl = [self.url stringByAppendingString:kNegotiateRequest];

    prepareRequest = ^(NSMutableURLRequest * request){
#if TARGET_IPHONE || TARGET_IPHONE_SIMULATOR
        [request setValue:[self createUserAgentString:@"SignalR.Client.iOS"] forHTTPHeaderField:@"User-Agent"];
#elif TARGET_OS_MAC
        [request setValue:[self createUserAgentString:@"SignalR.Client.MAC"] forHTTPHeaderField:@"User-Agent"];
#endif
    };
    
    [[HttpHelper sharedHttpRequestManager] postAsync:self url:negotiateUrl requestPreparer:prepareRequest onCompletion:
     
     ^(SRConnection *connection, id response) {
        if([response isKindOfClass:[NSString class]])
        {        
            SRNegotiationResponse *negotiationResponse = [[SRNegotiationResponse alloc] initWithDictionary:[[SBJsonParser new] objectWithString:response]];
#if DEBUG
            NSLog(@"%@",negotiationResponse);
#endif
            [self verifyProtocolVersion:negotiationResponse.protocolVersion];

            if(negotiationResponse.connectionId){
                self.connectionId = negotiationResponse.connectionId;
                            
                [self.transport start:connection];
            
                _initialized = YES;
        
                if(self.delegate &&[self.delegate respondsToSelector:@selector(SRConnectionDidOpen:)]){
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

//TODO: Parse Version into Version Object like C#
- (void)verifyProtocolVersion:(NSString *)versionString
{
    if(![versionString isEqualToString:@"1.0"])
    {
        [NSException raise:@"InvalidOperationException" format:@"Incompatible Protocol Version"];
    }
}

- (void)stop
{
    if (!_initialized)
        return;
    
    @try 
    {
        [self.transport stop:self];
        
        if(closed != nil)
        {
            self.closed();
        }
    }
    @finally 
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(SRConnectionDidClose:)]) {
            [self.delegate SRConnectionDidClose:self];
        }
        
        active = NO;
        _initialized = NO;
    }
}

#pragma mark - 
#pragma mark Sending data

- (void)send:(NSString *)message
{
    [self send:message onCompletion:nil];
}

- (void)send:(NSString *)message onCompletion:(void(^)(SRConnection *, id))block
{
    if (!_initialized)
    {
        [NSException raise:@"InvalidOperationException" format:@"Start must be called before data can be sent"];
    }

    [self.transport send:self withData:message onCompletion:block];
}

#pragma mark - 
#pragma mark Received Data

- (void)didReceiveData:(NSString *)message
{
    if(received != nil)
    {
        self.received(message);
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(SRConnection:didReceiveData:)]) {
        [self.delegate SRConnection:self didReceiveData:message];
    }
}

- (void)didReceiveError:(NSError *)ex
{
    if(error != nil)
    {
        self.error(ex);
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(SRConnection:didReceiveError:)]) {
        [self.delegate SRConnection:self didReceiveError:ex];
    }
}

#pragma mark - 
#pragma mark Prepare Request

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

@end
