//
//  SRHubRegistrationData.h
//  SignalR
//
//  Created by Alex Billingsley on 11/2/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRSBJSON.h"

@interface SRHubRegistrationData : NSObject <SRSBJSON>

@property (strong, nonatomic, readwrite) NSString *name;
@property (strong, nonatomic, readwrite) NSMutableArray *methods;

@end
