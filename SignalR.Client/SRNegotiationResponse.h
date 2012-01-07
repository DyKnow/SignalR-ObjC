//
//  SRNegotiationResponse.h
//  SignalR
//
//  Created by Alex Billingsley on 11/1/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "SRSBJSON.h"

@interface SRNegotiationResponse : NSObject <SRSBJSON>

@property (strong, nonatomic, readwrite) NSString *connectionId;
@property (strong, nonatomic, readwrite) NSString *url;
@property (strong, nonatomic, readwrite) NSString *protocolVersion;

@end
