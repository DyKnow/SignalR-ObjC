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
#import "SRSignalRConfig.h"

#import "NSDictionary+QueryString.h"
#import "NSObject+SRJSON.h"

typedef NSString* (^onConnectionSending)();

@interface SRHubConnection ()

- (NSString *)_getUrl:(NSString *)URL useDefault:(BOOL)useDefault;

@end

@implementation SRHubConnection

@synthesize hubs = _hubs;

#pragma mark - 
#pragma mark Initialization

+ (SRHubConnection *)connectionWithURL:(NSString *)URL
{
    return [[SRHubConnection alloc] initWithURL:URL];
}

+ (SRHubConnection *)connectionWithURL:(NSString *)url query:(NSDictionary *)queryString
{
    return [[SRHubConnection alloc] initWithURL:url queryString:[queryString stringWithFormEncodedComponents]];
}

+ (SRHubConnection *)connectionWithURL:(NSString *)url queryString:(NSString *)queryString
{
    return [[SRHubConnection alloc] initWithURL:url queryString:queryString];
}

- (id)initWithURL:(NSString *)URL
{
    return [self initWithURL:URL useDefault:YES];
}

- (id)initWithURL:(NSString *)URL useDefault:(BOOL)useDefault
{
    if ((self = [super initWithURL:[self _getUrl:URL useDefault:useDefault]])) 
    {
        _hubs = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id)initWithURL:(NSString *)url queryString:(NSString *)queryString
{
    if ((self = [super initWithURL:url queryString:queryString])) 
    {
        _hubs = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id)initWithURL:(NSString *)url query:(NSDictionary *)queryString
{
    if ((self = [super initWithURL:url query:queryString])) 
    {
        _hubs = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (SRHubProxy *)createProxy:(NSString *)hubName
{
#if DEBUG_CONNECTION
    SR_DEBUG_LOG(@"[CONNECTION] will create proxy %@",hubName);
#endif
    SRHubProxy *hubProxy;
    if([_hubs objectForKey:[hubName lowercaseString]] == nil)
    {
        hubProxy = [[SRHubProxy alloc] initWithConnection:self hubName:[hubName lowercaseString]];
        [_hubs setObject:hubProxy forKey:[hubName lowercaseString]];
    }
    return hubProxy;
}

#pragma mark - 
#pragma mark Private

- (NSString *)_getUrl:(NSString *)URL useDefault:(BOOL)useDefault
{
    if([URL hasSuffix:@"/"] == false)
    {
        URL = [URL stringByAppendingString:@"/"];
    }
    
    if(useDefault)
    {
        return [URL stringByAppendingString:@"signalr"];
    }
    
    return URL;
}

#pragma mark - 
#pragma mark Connection management

- (void)start:(id<SRClientTransport>)transport
{
    __unsafe_unretained NSMutableDictionary *hubs_ = _hubs;

    self.sending = ^()
    {    
        NSMutableArray *dataFromHub = [[NSMutableArray alloc] init];

        for(id key in hubs_)
        {
            SRHubRegistrationData *registration = [[SRHubRegistrationData alloc] init];
            registration.name = [[hubs_ objectForKey:key] hubName];
            [dataFromHub addObject:registration];
        }
        
        NSString *data = [dataFromHub SRJSONRepresentation];
        
        return data;
    };
    
    [super start:transport];
}

- (void)stop
{
    self.sending = nil;
    [super stop];
}

- (void)didReceiveData:(NSString *)data
{
    if([data isKindOfClass:[NSString class]])
    {
        SRHubInvocation *invocation = [[SRHubInvocation alloc] initWithDictionary:[data SRJSONValue]];
        SRHubProxy *hubProxy = [_hubs objectForKey:[invocation.hub lowercaseString]];
        if(hubProxy)
        {
            if(invocation.state != nil)
            {
                for (id key in invocation.state)
                {
                    
                    [hubProxy setMember:key object:[invocation.state objectForKey:key]];
                }
            }
            [hubProxy invokeEvent:invocation.method withArgs:invocation.args];
        }
    }
    
    [super didReceiveData:data];
}

- (void)dealloc
{
    _hubs = nil;
}

@end
