//
//  SRNegotiationResponse.h
//  SignalR
//
//  Created by Alex Billingsley on 11/1/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRSBJSON.h"

@interface SRNegotiationResponse : NSObject <SRSBJSON>

@property (strong, nonatomic, readonly) NSString *connectionId;
@property (strong, nonatomic, readonly) NSString *url;
@property (strong, nonatomic, readonly) NSString *protocolVersion;

@end
