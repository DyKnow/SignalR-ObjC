//
//  SRMockClientTransport.m
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 2/1/16.
//  Copyright © 2016 DyKnow LLC. All rights reserved.
//

#import "SRMockClientTransport.h"
#import <OCMock/OCMock.h>
#import <AFNetworking/AFNetworking.h>
#import "SRClientTransportInterface.h"
#import "SRNegotiationResponse.h"

@implementation SRMockClientTransport

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

+ (id)negotiateForTransport:(id <SRClientTransportInterface>)transport
                 statusCode:(NSNumber *)statusCode
                       json:(id)json; {
    return [self negotiateForTransport:transport statusCode:statusCode json:json callback:4];
}

+ (id)negotiateForMockTransport:(id)transportMock
                 statusCode:(NSNumber *)statusCode
                       json:(id)json; {
    return [self negotiateForMockTransport:transportMock statusCode:statusCode json:json callback:4];
}

+ (id)negotiateForTransport:(id <SRClientTransportInterface>)transport
                 statusCode:(NSNumber *)statusCode
                       json:(id)json
                   callback:(NSInteger)callbackIndex; {
    return [[self class] negotiateForMockTransport:[OCMockObject partialMockForObject:transport] statusCode:statusCode json:json callback:callbackIndex];
}

+ (id)negotiateForMockTransport:(id)transportMock
                     statusCode:(NSNumber *)statusCode
                           json:(id)json
                       callback:(NSInteger)callbackIndex; {
    return [[self class] negotiateStub:transportMock statusCode:statusCode json:json callback:callbackIndex];
}


+ (id)negotiateForTransport:(id <SRClientTransportInterface>)transport
                 statusCode:(NSNumber *)statusCode
                      error:(NSError *)error {
    return [self negotiateForTransport:transport statusCode:statusCode error:error callback:4];
}

+ (id)negotiateForMockTransport:(id)transportMock
                 statusCode:(NSNumber *)statusCode
                      error:(NSError *)error {
    return [self negotiateForMockTransport:transportMock statusCode:statusCode error:error callback:4];
}

+ (id)negotiateForTransport:(id <SRClientTransportInterface>)transport
                 statusCode:(NSNumber *)statusCode
                      error:(NSError *)error
                   callback:(NSInteger)callbackIndex; {
    return [[self class] negotiateForMockTransport:[OCMockObject partialMockForObject:transport] statusCode:statusCode error:error callback:callbackIndex];
}

+ (id)negotiateForMockTransport:(id)transportMock
                         statusCode:(NSNumber *)statusCode
                               error:(NSError *)error
                           callback:(NSInteger)callbackIndex; {
    return [[self class] negotiateStub:transportMock statusCode:statusCode json:error callback:callbackIndex];
}

#pragma mark -
#pragma mark Start

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

+ (id)startForTransport:(id <SRClientTransportInterface>)transport
             statusCode:(NSNumber *)statusCode
                   json:(id)json; {
    return [self startForTransport:transport statusCode:statusCode json:json callback:4];
}

+ (id)startForMockTransport:(id )transportMock
                 statusCode:(NSNumber *)statusCode
                       json:(id)json; {
    return [self startForMockTransport:transportMock statusCode:statusCode json:json callback:4];
}

+ (id)startForTransport:(id <SRClientTransportInterface>)transport
             statusCode:(NSNumber *)statusCode
                   json:(id)json
               callback:(NSInteger)callbackIndex; {
    return [[self class] startForMockTransport:[OCMockObject partialMockForObject:transport] statusCode:statusCode json:json callback:callbackIndex];
}

+ (id)startForMockTransport:(id)transportMock
                 statusCode:(NSNumber *)statusCode
                       json:(id)json
                   callback:(NSInteger)callbackIndex; {
    return [[self class] startStub:transportMock statusCode:statusCode json:json callback:callbackIndex];
}


+ (id)startForTransport:(id <SRClientTransportInterface>)transport
             statusCode:(NSNumber *)statusCode
                  error:(NSError *)error {
    return [self startForTransport:transport statusCode:statusCode error:error callback:4];
}


+ (id)startForMockTransport:(id)transportMock
             statusCode:(NSNumber *)statusCode
                  error:(NSError *)error {
    return [self startForMockTransport:transportMock statusCode:statusCode error:error callback:4];
}

+ (id)startForTransport:(id <SRClientTransportInterface>)transport
             statusCode:(NSNumber *)statusCode
                  error:(NSError *)error
               callback:(NSInteger)callbackIndex; {
    return [[self class] startForMockTransport:[OCMockObject partialMockForObject:transport] statusCode:statusCode error:error callback:callbackIndex];
}

+ (id)startForMockTransport:(id)transportMock
                 statusCode:(NSNumber *)statusCode
                      error:(NSError *)error
                   callback:(NSInteger)callbackIndex; {
    return [[self class] startStub:transportMock statusCode:statusCode json:error callback:callbackIndex];
}

#pragma mark -
#pragma mark Send

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

+ (id)sendForTransport:(id <SRClientTransportInterface>)transport
            statusCode:(NSNumber *)statusCode
                  json:(id)json; {
    return [self sendForTransport:transport statusCode:statusCode json:json callback:5];
}

+ (id)sendForMockTransport:(id)transportMock
            statusCode:(NSNumber *)statusCode
                      json:(id)json; {
    return [self sendForMockTransport:transportMock statusCode:statusCode json:json callback:5];
}

+ (id)sendForTransport:(id <SRClientTransportInterface>)transport
            statusCode:(NSNumber *)statusCode
                  json:(id)json
              callback:(NSInteger)callbackIndex; {
    return [[self class] sendForMockTransport:[OCMockObject partialMockForObject:transport] statusCode:statusCode json:json callback:callbackIndex];
}

+ (id)sendForMockTransport:(id)transportMock
                 statusCode:(NSNumber *)statusCode
                       json:(id)json
                   callback:(NSInteger)callbackIndex; {
    return [[self class] sendStub:transportMock data:[OCMArg any] statusCode:statusCode json:json callback:callbackIndex];
}


+ (id)sendForTransport:(id <SRClientTransportInterface>)transport
            statusCode:(NSNumber *)statusCode
                 error:(NSError *)error {
    return [self sendForTransport:transport statusCode:statusCode error:error callback:5];
}

+ (id)sendForMockTransport:(id)transportMock
            statusCode:(NSNumber *)statusCode
                 error:(NSError *)error {
    return [self sendForMockTransport:transportMock statusCode:statusCode error:error callback:5];
}

+ (id)sendForTransport:(id <SRClientTransportInterface>)transport
            statusCode:(NSNumber *)statusCode
                 error:(NSError *)error
              callback:(NSInteger)callbackIndex; {
    return [[self class] sendForMockTransport:[OCMockObject partialMockForObject:transport] statusCode:statusCode error:error callback:callbackIndex];
}

+ (id)sendForMockTransport:(id)transportMock
                statusCode:(NSNumber *)statusCode
                     error:(NSError *)error
                  callback:(NSInteger)callbackIndex; {
    return [[self class] sendStub:transportMock data:[OCMArg any] statusCode:statusCode json:error callback:callbackIndex];
}

@end
