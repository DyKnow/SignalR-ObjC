//
//  SRTransport.h
//  SignalR
//
//  Created by Alex Billingsley on 1/7/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRClientTransport.h"

@class SRLongPollingTransport;

@interface SRTransport : NSObject

@property (strong, nonatomic, readonly) id <SRClientTransport> longPolling;
@property (strong, nonatomic, readonly) id <SRClientTransport> serverSentEvents;

+ (id <SRClientTransport>)LongPolling;

@end
