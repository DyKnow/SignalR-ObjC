//
//  SRMockClientTransport+SSE.m
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 7/21/16.
//  Copyright © 2016 DyKnow LLC. All rights reserved.
//

#import "SRMockClientTransport+SSE.h"
#import <URLMock/UMKMockURLProtocol.h>
#import <URLMock/UMKMockHTTPResponder.h>
#import <AFNetworking/AFURLRequestSerialization.h>
#import "SRServerSentEventsTransport.h"
#import "SRMockSSEResponder.h"

@implementation SRMockClientTransport (SSE)

+ (SRServerSentEventsTransport *)sse {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.protocolClasses = @[[UMKMockURLProtocol class]];
    SRServerSentEventsTransport *transport = [[SRServerSentEventsTransport alloc] initWithSessionConfiguration:configuration];
    return transport;
}

+ (NSString *)jsonToSSE:(id)json {
    NSString *stringifiedJson = [[[[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    return [NSString stringWithFormat:@"data: %@\n\n",stringifiedJson];
}

+ (id <UMKMockURLResponder>)connectTransport:(id <SRClientTransportInterface>)transport
                                   responder:(id <UMKMockURLResponder>)responder {
    return [self expectMockRequestWithHTTPMethod:@"GET" path:@"connect" responder:responder];
}

+ (id <UMKMockURLResponder>)reconnectTransport:(id <SRClientTransportInterface>)transport
                                     responder:(id <UMKMockURLResponder>)responder {
    return [self expectMockRequestWithHTTPMethod:@"GET" path:@"reconnect" responder:responder];
}

+ (SRMockSSEResponder *)connectTransport:(id <SRClientTransportInterface>)transport
                              statusCode:(NSNumber *)statusCode
                                    json:(id)json; {
    id messages = @[
        [@"data: initialized\n\n" dataUsingEncoding:NSUTF8StringEncoding],
        [[self jsonToSSE:json] dataUsingEncoding:NSUTF8StringEncoding]
    ];
    
    SRMockSSEResponder *responder = [[SRMockSSEResponder alloc] initWithStatusCode:[statusCode integerValue]
                                                                       eventStream:messages];
    return [self connectTransport:transport responder:responder];
}

+ (id <UMKMockURLResponder>)connectTransport:(id <SRClientTransportInterface>)transport
                                  statusCode:(NSNumber *)statusCode
                                       error:(NSError *)error; {
    UMKMockHTTPResponder * responder = [UMKMockHTTPResponder mockHTTPResponderWithError:error];
    return [self connectTransport:transport responder:responder];
}

+ (SRMockSSEResponder *)reconnectTransport:(id <SRClientTransportInterface>)transport
                                statusCode:(NSNumber *)statusCode
                                      json:(id)json; {
    id messages = @[
        [@"data: initialized\n\n" dataUsingEncoding:NSUTF8StringEncoding],
        [[self jsonToSSE:json] dataUsingEncoding:NSUTF8StringEncoding]
    ];
    
    SRMockSSEResponder *responder = [[SRMockSSEResponder alloc] initWithStatusCode:[statusCode integerValue]
                                                                       eventStream:messages];
    return [self reconnectTransport:transport responder:responder];
}

+ (id <UMKMockURLResponder>)reconnectTransport:(id <SRClientTransportInterface>)transport
                                    statusCode:(NSNumber *)statusCode
                                         error:(NSError *)error; {
    UMKMockHTTPResponder * responder = [UMKMockHTTPResponder mockHTTPResponderWithError:error];
    return [self reconnectTransport:transport responder:responder];
}

@end
