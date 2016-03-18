//
//  SRMockClientTransport.h
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 2/1/16.
//  Copyright © 2016 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRClientTransportInterface.h"

@interface SRMockClientTransport : NSObject

+ (id)negotiateForTransport:(id <SRClientTransportInterface>)transport
                 statusCode:(NSNumber *)statusCode
                       json:(id)json;

+ (id)negotiateForMockTransport:(id)transportMock
                     statusCode:(NSNumber *)statusCode
                           json:(id)json;

+ (id)negotiateForTransport:(id <SRClientTransportInterface>)transport
                 statusCode:(NSNumber *)statusCode
                      error:(NSError *)error;

+ (id)negotiateForMockTransport:(id)transportMock
                     statusCode:(NSNumber *)statusCode
                          error:(NSError *)error;

+ (id)startForTransport:(id <SRClientTransportInterface>)transport
             statusCode:(NSNumber *)statusCode
                   json:(id)json;

+ (id)startForMockTransport:(id )transportMock
                 statusCode:(NSNumber *)statusCode
                       json:(id)json;

+ (id)startForTransport:(id <SRClientTransportInterface>)transport
             statusCode:(NSNumber *)statusCode
                  error:(NSError *)error;

+ (id)startForMockTransport:(id)transportMock
                 statusCode:(NSNumber *)statusCode
                      error:(NSError *)error;

+ (id)sendForTransport:(id <SRClientTransportInterface>)transport
             statusCode:(NSNumber *)statusCode
                   json:(id)json;

+ (id)sendForMockTransport:(id)transportMock
                statusCode:(NSNumber *)statusCode
                      json:(id)json;

+ (id)sendForTransport:(id <SRClientTransportInterface>)transport
             statusCode:(NSNumber *)statusCode
                  error:(NSError *)error;

+ (id)sendForMockTransport:(id)transportMock
                statusCode:(NSNumber *)statusCode
                     error:(NSError *)error;

@end
