//
//  SRTransport.m
//  SignalR
//
//  Created by Alex Billingsley on 1/7/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import "SRTransport.h"

#import "SRLongPollingTransport.h"

@implementation SRTransport

@synthesize longPolling = _longPolling;
@synthesize serverSentEvents = _serverSentEvents;

+ (SRLongPollingTransport *)LongPolling
{
    SRTransport *transport = [[SRTransport alloc] init];
    
    return transport.longPolling;
}

- (id)init
{
    if (self = [super init])
    {
        _longPolling = [[SRLongPollingTransport alloc] init];
        _serverSentEvents = nil;
    }
    return self;
}
@end
