//
//  SRMockClientTransport+LP.m
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 7/25/16.
//  Copyright © 2016 DyKnow LLC. All rights reserved.
//

#import "SRMockClientTransport+LP.h"
#import <URLMock/UMKMockURLProtocol.h>
#import <URLMock/UMKMockHTTPResponder.h>
#import <AFNetworking/AFURLRequestSerialization.h>
#import "SRLongPollingTransport.h"
#import "SRMockLPResponder.h"

@implementation SRMockLPTransport

+ (SRLongPollingTransport *)transport {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.protocolClasses = @[[UMKMockURLProtocol class]];
    SRLongPollingTransport *transport = [[SRLongPollingTransport alloc] initWithSessionConfiguration:configuration];
    return transport;
}

+ (SRMockLPResponder *)connectTransport:(id <SRClientTransportInterface>)transport
                             statusCode:(NSNumber *)statusCode
                                   json:(id)json; {
    SRMockLPResponder * responder = [SRMockLPResponder mockHTTPResponderWithStatusCode:[statusCode integerValue]];
    if (json) {
        [responder setBodyWithJSONObject:json];
    }
    return [self connectTransport:transport responder:responder];
}

+ (SRMockLPResponder *)reconnectTransport:(id <SRClientTransportInterface>)transport
                               statusCode:(NSNumber *)statusCode
                                     json:(id)json; {
    SRMockLPResponder * responder = [SRMockLPResponder mockHTTPResponderWithStatusCode:[statusCode integerValue]];
    if (json) {
        [responder setBodyWithJSONObject:json];
    }
    return [self reconnectTransport:transport responder:responder];
}

+ (id <UMKMockURLResponder>)pollTransport:(id <SRClientTransportInterface>)transport
                                responder:(id <UMKMockURLResponder>)responder; {
    return [self expectMockRequestWithHTTPMethod:@"GET" path:@"poll" responder:responder];
}

+ (SRMockLPResponder *)pollTransport:(id <SRClientTransportInterface>)transport
                          statusCode:(NSNumber *)statusCode
                                json:(id)json {
    SRMockLPResponder * responder = [SRMockLPResponder mockHTTPResponderWithStatusCode:[statusCode integerValue]];
    if (json) {
        [responder setBodyWithJSONObject:json];
    }
    return [self pollTransport:transport responder:responder];
}

+ (id <UMKMockURLResponder>)pollTransport:(id <SRClientTransportInterface>)transport
                               statusCode:(NSNumber *)statusCode
                                    error:(NSError *)error; {
    UMKMockHTTPResponder * responder = [UMKMockHTTPResponder mockHTTPResponderWithError:error];
    return [self pollTransport:transport responder:responder];
}
@end
