//
//  SRHubConnection.m
//  SignalR
//
//  Created by Alex Billingsley on 10/31/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "SRHubConnection.h"

#import "SBJson.h"
#import "SRHubProxy.h"
#import "SRHubRegistrationData.h"
#import "SRHubClientInvocation.h"

typedef NSString* (^onConnectionSending)();
typedef void (^onConnectionReceived)(NSString *);

@interface SRHubConnection()

- (NSString *)_getUrl:(NSString *)URL;

@end

@implementation SRHubConnection

@synthesize hubs = _hubs;

#pragma mark - Initialization

+ (SRHubConnection *)connectionWithURL:(NSString *)URL
{
    return [[SRHubConnection alloc] initWithURL:URL];
}

- (id)initWithURL:(NSString *)URL
{
    if ((self = [super initWithURL:[self _getUrl:URL]])) {
        _hubs = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (SRHubProxy *)createProxy:(NSString *)hubName
{
    SRHubProxy *hubProxy;
    if([_hubs objectForKey:hubName] == nil)
    {
        hubProxy = [[SRHubProxy alloc] initWithConnection:self hubName:hubName];
        [_hubs setObject:hubProxy forKey:hubName];
    }
    return hubProxy;
}

#pragma mark - Private

- (NSString *)_getUrl:(NSString *)URL
{
    if([URL hasSuffix:@"/"] == false){
        URL = [URL stringByAppendingString:@"/"];
    }
    return [URL stringByAppendingString:@"signalr"];
}

#pragma mark - Connection management

- (void)start
{
    self.sending = ^()
    {    
        NSMutableArray *dataFromHub = [[NSMutableArray alloc] init];
        for(id key in _hubs)
        {
            SRHubRegistrationData *registration = [[SRHubRegistrationData alloc] init];
            registration.name = [[_hubs objectForKey:key] hubName];
            registration.methods = [NSMutableArray arrayWithArray:[[_hubs objectForKey:key] getSubscriptions]];
            [dataFromHub addObject:registration];
        }
        
        NSString *data = [[SBJsonWriter new] stringWithObject:dataFromHub];
        
        return data;
    };
    
    self.received = ^(NSString * data) {
        if([data isKindOfClass:[NSString class]])
        {
            SRHubClientInvocation *invocation = [[SRHubClientInvocation alloc] initWithDictionary:[[SBJsonParser new] objectWithString:data]];
            SRHubProxy *hubProxy = [_hubs objectForKey:invocation.hub];
            if(hubProxy){
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
    [super start];
}

- (void)stop
{
    self.sending = nil;
    self.received = nil;
    [super stop];
}

@end
