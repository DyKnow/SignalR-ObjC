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

@interface SRMockClientTransport (SSE)

+ (SRServerSentEventsTransport *)sse;
+ (id <UMKMockURLResponder>)connectTransport:(id <SRClientTransportInterface>)transport
                                   responder:(id <UMKMockURLResponder>)responder;

+ (SRMockSSEResponder *)connectTransport:(id <SRClientTransportInterface>)transport
                              statusCode:(NSNumber *)statusCode
                                    json:(id)json;

+ (id <UMKMockURLResponder>)connectTransport:(id <SRClientTransportInterface>)transport
                                  statusCode:(NSNumber *)statusCode
                                       error:(NSError *)error;

+ (id <UMKMockURLResponder>)reconnectTransport:(id <SRClientTransportInterface>)transport
                                     responder:(id <UMKMockURLResponder>)responder;

+ (SRMockSSEResponder *)reconnectTransport:(id <SRClientTransportInterface>)transport
                                statusCode:(NSNumber *)statusCode
                                      json:(id)json;

+ (id <UMKMockURLResponder>)reconnectTransport:(id <SRClientTransportInterface>)transport
                                    statusCode:(NSNumber *)statusCode
                                         error:(NSError *)error;
@end
