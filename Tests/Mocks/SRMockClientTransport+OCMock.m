//
//  SRMockClientTransport+OCMock.m
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 7/21/16.
//  Copyright © 2016 DyKnow LLC. All rights reserved.
//

#import "SRMockClientTransport+OCMock.h"
#import <AFNetworking/AFNetworking.h>
#import "SRClientTransportInterface.h"
#import "SRNegotiationResponse.h"

@implementation SRMockClientTransport (OCMock)

+ (id)negotiateStub:(id)mock
         statusCode:(NSNumber *)statusCode
               json:(id)json
           callback:(NSInteger)callbackIndex {
    [[[mock stub] andDo:^(NSInvocation *invocation) {
        void (^completionHandler)(SRNegotiationResponse * response, NSError *error);
        __unsafe_unretained void (^negotiateCallback)(SRNegotiationResponse *, NSError *) = nil;
        [invocation getArgument: &negotiateCallback atIndex:callbackIndex];
        completionHandler = negotiateCallback;
        
        if ([statusCode  isEqual: @200]) {
            if (completionHandler) {
                completionHandler([[SRNegotiationResponse alloc ]initWithDictionary:json], nil);
            }
        } else {
            if (completionHandler) {
                completionHandler(nil, json);
            }
        }
    }] negotiate:[OCMArg any] connectionData:[OCMArg any] completionHandler:[OCMArg any]];
    return mock;
}

+ (id)negotiateForMockTransport:(id)transportMock {
    return [[self class] negotiateForMockTransport:transportMock statusCode:@200 json:@{
        @"ConnectionId": @"10101",
        @"ConnectionToken": @"10101010101",
        @"DisconnectTimeout": @30,
        @"ProtocolVersion": @"1.3.0.0",
        @"TransportConnectTimeout": @10
    }];
}

+ (id)negotiateForMockTransport:(id)transportMock
                     statusCode:(NSNumber *)statusCode
                           json:(id)json; {
    return [[self class] negotiateStub:transportMock statusCode:statusCode json:json callback:4];
}

+ (id)negotiateForMockTransport:(id)transportMock
                     statusCode:(NSNumber *)statusCode
                          error:(NSError *)error {
    return [[self class] negotiateStub:transportMock statusCode:statusCode json:error callback:4];
}

+ (id)startStub:(id)mock
     statusCode:(NSNumber *)statusCode
           json:(id)json
       callback:(NSInteger)callbackIndex {
    [[[mock stub] andDo:^(NSInvocation *invocation) {
        void (^completionHandler)(id response, NSError *error);
        __unsafe_unretained void (^startCallback)(id, NSError *) = nil;
        [invocation getArgument: &startCallback atIndex:callbackIndex];
        completionHandler = startCallback;
        
        if ([statusCode  isEqual: @200]) {
            if (completionHandler) {
                completionHandler(json, nil);
            }
        } else {
            if (completionHandler) {
                completionHandler(nil, json);
            }
        }
    }] start:[OCMArg any] connectionData:[OCMArg any] completionHandler:[OCMArg any]];
    return mock;
}

+ (id)startForMockTransport:(id)transportMock
                 statusCode:(NSNumber *)statusCode
                       json:(id)json  {
    return [[self class] startStub:transportMock statusCode:statusCode json:json callback:4];
}

+ (id)startForMockTransport:(id)transportMock
                 statusCode:(NSNumber *)statusCode
                      error:(NSError *)error {
    return [[self class] startStub:transportMock statusCode:statusCode json:error callback:4];
}

+ (id)sendStub:(id)mock
          data:(id)dataStub
    statusCode:(NSNumber *)statusCode
          json:(id)json
      callback:(NSInteger)callbackIndex {
    [[[mock stub] andDo:^(NSInvocation *invocation) {
        void (^completionHandler)(id response, NSError *error);
        __unsafe_unretained void (^sendCallback)(id, NSError *) = nil;
        [invocation getArgument: &sendCallback atIndex:callbackIndex];
        completionHandler = sendCallback;
        
        if ([statusCode  isEqual: @200]) {
            if (completionHandler) {
                completionHandler(json, nil);
            }
        } else {
            if (completionHandler) {
                completionHandler(nil, json);
            }
        }
    }] send:[OCMArg any] data:dataStub connectionData:[OCMArg any] completionHandler:[OCMArg any]];
    return mock;
}

+ (id)sendForMockTransport:(id)transportMock
                statusCode:(NSNumber *)statusCode
                      json:(id)json {
    return [[self class] sendStub:transportMock data:[OCMArg any] statusCode:statusCode json:json callback:5];
}

+ (id)sendForMockTransport:(id)transportMock
                statusCode:(NSNumber *)statusCode
                     error:(NSError *)error  {
    return [[self class] sendStub:transportMock data:[OCMArg any] statusCode:statusCode json:error callback:5];
}
@end
