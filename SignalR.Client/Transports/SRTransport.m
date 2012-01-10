//
//  SRTransport.m
//  SignalR
//
//  Created by Alex Billingsley on 1/7/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import "SRTransport.h"

#import "SRLongPollingTransport.h"
#import "SRServerSentEventsTransport.h"

@interface SRTransport()

@end

@implementation SRTransport

@synthesize longPolling = _longPolling;
@synthesize serverSentEvents = _serverSentEvents;

+ (id <SRClientTransport>)LongPolling
{
    SRTransport *transport = [[SRTransport alloc] init];
    
    return transport.longPolling;
}

+ (id <SRClientTransport>)ServerSentEvents
{
    SRTransport *transport = [[SRTransport alloc] init];
    
    return transport.serverSentEvents;
}

- (id)init
{
    if (self = [super init])
    {
        _longPolling = [[SRLongPollingTransport alloc] init];
        _serverSentEvents = [[SRServerSentEventsTransport alloc] init];
    }
    return self;
}

@end
