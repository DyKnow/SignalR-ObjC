//
//  SRLongPollingTransport.h
//  SignalR
//
//  Created by Alex Billingsley on 10/17/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRHttpBasedTransport.h"

@interface SRLongPollingTransport : SRHttpBasedTransport

@property (assign, nonatomic, readwrite) NSInteger reconnectDelay;

@end