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
#import "SRSignalRConfig.h"

#import "NSObject+SRJSON.h"
#import "SRHubProxy.h"
#import "SRHubRegistrationData.h"
#import "SRHubClientInvocation.h"

#if NS_BLOCKS_AVAILABLE
typedef NSString* (^onConnectionSending)();
typedef void (^onConnectionReceived)(NSString *);
#endif

@interface SRHubConnection ()

- (NSString *)_getUrl:(NSString *)URL;

@end

@implementation SRHubConnection

@synthesize hubs = _hubs;

#pragma mark - 
#pragma mark Initialization

+ (SRHubConnection *)connectionWithURL:(NSString *)URL
{
    return [[SRHubConnection alloc] initWithURL:URL];
}

- (id)initWithURL:(NSString *)URL
{
    if ((self = [super initWithURL:[self _getUrl:URL]])) 
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
    if([_hubs objectForKey:hubName] == nil)
    {
        hubProxy = [[SRHubProxy alloc] initWithConnection:self hubName:hubName];
        [_hubs setObject:hubProxy forKey:hubName];
    }
    return hubProxy;
}

#pragma mark - 
#pragma mark Private

- (NSString *)_getUrl:(NSString *)URL
{
    if([URL hasSuffix:@"/"] == false)
    {
        URL = [URL stringByAppendingString:@"/"];
    }
    return [URL stringByAppendingString:@"signalr"];
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
            registration.methods = [NSMutableArray arrayWithArray:[[hubs_ objectForKey:key] getSubscriptions]];
            [dataFromHub addObject:registration];
        }
        
        NSString *data = [dataFromHub SRJSONRepresentation];
        
        return data;
    };
    
    self.received = ^(NSString * data) 
    {
        if([data isKindOfClass:[NSString class]])
        {
            SRHubClientInvocation *invocation = [[SRHubClientInvocation alloc] initWithDictionary:[data SRJSONValue]];
            SRHubProxy *hubProxy = [hubs_ objectForKey:invocation.hub];
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
    };
    [super start:transport];
}

- (void)stop
{
    self.sending = nil;
    self.received = nil;
    [super stop];
}

- (void)dealloc
{
    _hubs = nil;
}

@end
