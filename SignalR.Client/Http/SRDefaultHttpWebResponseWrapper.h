//
//  SRDefaultHttpWebResponseWrapper.h
//  SignalR.Samples
//
//  Created by Alex Billingsley on 6/8/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRResponse.h"

@interface SRDefaultHttpWebResponseWrapper : NSObject <SRResponse>

- (id)initWithResponse:(id)response;

@end
