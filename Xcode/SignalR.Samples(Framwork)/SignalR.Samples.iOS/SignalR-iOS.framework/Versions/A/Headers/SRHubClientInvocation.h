//
//  SRHubClientInvocation.h
//  SignalR
//
//  Created by Alex Billingsley on 11/7/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRSBJSON.h"

@interface SRHubClientInvocation : NSObject <SRSBJSON>

@property (strong, nonatomic, readwrite) NSString *hub;
@property (strong, nonatomic, readwrite) NSString *method;
@property (strong, nonatomic, readwrite) NSMutableArray *args;
@property (strong, nonatomic, readwrite) NSMutableDictionary *state;

@end
