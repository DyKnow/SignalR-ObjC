//
//  SRMockClientTransport+LP.h
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 7/25/16.
//  Copyright © 2016 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRMockClientTransport.h"

@class SRLongPollingTransport;
@class SRMockLPResponder;

@interface SRMockLPTransport : SRMockClientTransport

+ (SRLongPollingTransport *)transport;

+ (SRMockLPResponder *)connectTransport:(id <SRClientTransportInterface>)transport
                             statusCode:(NSNumber *)statusCode
                                   json:(id)json;

+ (SRMockLPResponder *)reconnectTransport:(id <SRClientTransportInterface>)transport
                               statusCode:(NSNumber *)statusCode
                                     json:(id)json;

+ (id <UMKMockURLResponder>)pollTransport:(id <SRClientTransportInterface>)transport
                                responder:(id <UMKMockURLResponder>)responder;

+ (SRMockLPResponder *)pollTransport:(id <SRClientTransportInterface>)transport
                          statusCode:(NSNumber *)statusCode
                                json:(id)json;

+ (id <UMKMockURLResponder>)pollTransport:(id <SRClientTransportInterface>)transport
                               statusCode:(NSNumber *)statusCode
                                    error:(NSError *)error;
@end
