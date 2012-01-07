//
//  SRHubResult.h
//  SignalR
//
//  Created by Alex Billingsley on 11/2/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRSBJSON.h"

@interface SRHubResult : NSObject <SRSBJSON>

@property (strong, nonatomic, readwrite) id result;
@property (strong, nonatomic, readwrite) NSString *error;
@property (strong, nonatomic, readwrite) NSDictionary *state;

@end
