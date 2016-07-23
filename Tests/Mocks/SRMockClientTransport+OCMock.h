//
//  SRMockClientTransport+OCMock.h
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 7/21/16.
//  Copyright © 2016 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import "SRMockClientTransport.h"

@interface SRMockClientTransport (OCMock)

+ (id)negotiateForMockTransport:(id)transportMock;

+ (id)negotiateForMockTransport:(id)transportMock
                     statusCode:(NSNumber *)statusCode
                           json:(id)json;

+ (id)negotiateForMockTransport:(id)transportMock
                     statusCode:(NSNumber *)statusCode
                          error:(NSError *)error;

+ (id)startForMockTransport:(id )transportMock
                 statusCode:(NSNumber *)statusCode
                       json:(id)json;

+ (id)startForMockTransport:(id)transportMock
                 statusCode:(NSNumber *)statusCode
                      error:(NSError *)error;

+ (id)sendForMockTransport:(id)transportMock
                statusCode:(NSNumber *)statusCode
                      json:(id)json;

+ (id)sendForMockTransport:(id)transportMock
                statusCode:(NSNumber *)statusCode
                     error:(NSError *)error;
@end
