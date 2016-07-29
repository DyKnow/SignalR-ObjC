//
//  SRMockClientTransport+SSE.h
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 7/21/16.
//  Copyright © 2016 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRMockClientTransport.h"

@class SRServerSentEventsTransport;
@class SRMockSSEResponder;

@interface SRMockSSETransport : SRMockClientTransport

+ (SRServerSentEventsTransport *)transport;

+ (SRMockSSEResponder *)connectTransport:(id <SRClientTransportInterface>)transport
                              statusCode:(NSNumber *)statusCode
                                    json:(id)json;

+ (SRMockSSEResponder *)reconnectTransport:(id <SRClientTransportInterface>)transport
                                statusCode:(NSNumber *)statusCode
                                      json:(id)json;

@end
