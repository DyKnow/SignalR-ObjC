//
//  SRMockNegotiate.m
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 2/1/16.
//  Copyright © 2016 DyKnow LLC. All rights reserved.
//

#import "SRMockNegotiate.h"
#import <OCMock/OCMock.h>
#import <AFNetworking/AFNetworking.h>
#import "SRClientTransportInterface.h"
#import "SRNegotiationResponse.h"

@implementation SRMockNegotiate

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

+ (id)mockNegotiateForTransport:(id <SRClientTransportInterface>)transport
                     statusCode:(NSNumber *)statusCode
                           json:(id)json; {
    return [self mockNegotiateForTransport:transport statusCode:statusCode json:json callback:4];
}

+ (id)mockNegotiateForTransport:(id <SRClientTransportInterface>)transport
                     statusCode:(NSNumber *)statusCode
                           json:(id)json
                       callback:(NSInteger)callbackIndex; {
    return [[self class] mockNegotiateForMockTransport:[OCMockObject partialMockForObject:transport] statusCode:statusCode json:json callback:callbackIndex];
}

+ (id)mockNegotiateForMockTransport:(id)transportMock
                     statusCode:(NSNumber *)statusCode
                           json:(id)json
                       callback:(NSInteger)callbackIndex; {
    return [[self class] negotiateStub:transportMock statusCode:statusCode json:json callback:callbackIndex];
}


+ (id)mockNegotiateForTransport:(id <SRClientTransportInterface>)transport
                     statusCode:(NSNumber *)statusCode
                          error:(NSError *)error {
    return [self mockNegotiateForTransport:transport statusCode:statusCode error:error callback:4];
}

+ (id)mockNegotiateForTransport:(id <SRClientTransportInterface>)transport
                     statusCode:(NSNumber *)statusCode
                          error:(NSError *)error
                       callback:(NSInteger)callbackIndex; {
    return [[self class] mockNegotiateForMockTransport:[OCMockObject partialMockForObject:transport] statusCode:statusCode error:error callback:callbackIndex];
}

+ (id)mockNegotiateForMockTransport:(id)transportMock
                         statusCode:(NSNumber *)statusCode
                               error:(NSError *)error
                           callback:(NSInteger)callbackIndex; {
    return [[self class] negotiateStub:transportMock statusCode:statusCode json:error callback:callbackIndex];
}

@end
