//
//  SRMockNegotiate.h
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 2/1/16.
//  Copyright © 2016 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRClientTransportInterface.h"

@interface SRMockNegotiate : NSObject

+ (id)mockNegotiateForTransport:(id <SRClientTransportInterface>)transport
                     statusCode:(NSNumber *)statusCode
                           json:(id)json;

+ (id)mockNegotiateForTransport:(id <SRClientTransportInterface>)transport
                     statusCode:(NSNumber *)statusCode
                          error:(NSError *)error;

@end
