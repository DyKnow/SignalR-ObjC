//
//  SRServerSentEventsTransport.h
//  SignalR
//
//  Created by Alex Billingsley on 1/7/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRHttpBasedTransport.h"

@interface SRServerSentEventsTransport : SRHttpBasedTransport

@property (assign, nonatomic, readwrite) NSInteger connectionTimeout;

@end
