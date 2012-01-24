//
//  SRTransport.h
//  SignalR
//
//  Created by Alex Billingsley on 1/7/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRClientTransport.h"

@interface SRTransport : NSObject

@property (strong, nonatomic, readwrite) id <SRClientTransport> autoTransport;
@property (strong, nonatomic, readonly) id <SRClientTransport> serverSentEvents;
@property (strong, nonatomic, readonly) id <SRClientTransport> longPolling;

+ (id <SRClientTransport>)Auto;
+ (id <SRClientTransport>)ServerSentEvents;
+ (id <SRClientTransport>)LongPolling;

@end
