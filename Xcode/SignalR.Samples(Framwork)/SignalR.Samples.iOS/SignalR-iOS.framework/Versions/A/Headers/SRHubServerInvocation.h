//
//  SRHubServerInvocation.h
//  SignalR
//
//  Created by Alex Billingsley on 11/7/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRSBJSON.h"

@interface SRHubServerInvocation : NSObject <SRSBJSON>

@property (strong, nonatomic, readwrite) NSString *hub;
@property (strong, nonatomic, readwrite) NSString *action;
@property (strong, nonatomic, readwrite) NSMutableArray *data;
@property (strong, nonatomic, readwrite) NSMutableDictionary *state;

@end
