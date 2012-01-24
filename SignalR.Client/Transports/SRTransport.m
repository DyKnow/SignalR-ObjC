//
//  SRTransport.m
//  SignalR
//
//  Created by Alex Billingsley on 1/7/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import "SRTransport.h"

#import "SRAutoTransport.h"
#import "SRServerSentEventsTransport.h"
#import "SRLongPollingTransport.h"

@interface SRTransport()

@end

@implementation SRTransport

@synthesize autoTransport = _autoTransport;
@synthesize longPolling = _longPolling;
@synthesize serverSentEvents = _serverSentEvents;

+ (id <SRClientTransport>)Auto
{
    SRTransport *transport = [[SRTransport alloc] init];
    transport.autoTransport = [[SRAutoTransport alloc] init];
    
    return transport.autoTransport;
}

+ (id <SRClientTransport>)ServerSentEvents
{
    SRTransport *transport = [[SRTransport alloc] init];
    
    return transport.serverSentEvents;
}

+ (id <SRClientTransport>)LongPolling
{
    SRTransport *transport = [[SRTransport alloc] init];
    
    return transport.longPolling;
}

- (id)init
{
    if (self = [super init])
    {
        _serverSentEvents = [[SRServerSentEventsTransport alloc] init];
        _longPolling = [[SRLongPollingTransport alloc] init];
    }
    return self;
}

@end
