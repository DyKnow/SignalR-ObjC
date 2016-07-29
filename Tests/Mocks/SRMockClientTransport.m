//
//  SRMockClientTransport.m
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 2/1/16.
//  Copyright © 2016 DyKnow LLC. All rights reserved.
//

#import "SRMockClientTransport.h"
#import <URLMock/URLMock.h>
#import <AFNetworking/AFNetworking.h>
#import "SRClientTransportInterface.h"
#import "SRMockTransportRequest.h"

@implementation SRMockClientTransport

+ (id <UMKMockURLResponder>)expectMockRequestWithHTTPMethod:(NSString *)method
                                                       path:(NSString *)path
                                                  responder:(id <UMKMockURLResponder>)responder {
    SRMockTransportRequest *mockRequest = [[SRMockTransportRequest alloc] initWithHTTPMethod:method URL:[NSURL URLWithString:path relativeToURL:[NSURL URLWithString:@"http://localhost:0000"]]];
    [mockRequest setHeaders:[[AFHTTPRequestSerializer serializer] HTTPRequestHeaders]];
    [mockRequest setResponder:responder];
    [UMKMockURLProtocol expectMockRequest:mockRequest];
    return responder;
}

#pragma mark -
#pragma mark negotiate

+ (id)negotiateForTransport:(id <SRClientTransportInterface>)transport {
    return [[self class] negotiateForTransport:transport statusCode:@200 json:@{
       @"ConnectionId": @"c5baaf89-05a3-4e67-b308-9c11a79c1dbe",
       @"ConnectionTimeout": @110,
       @"ConnectionToken": @"CfDJ8BiCiEytZ/1KidtIZ+dO2+IR7kk2s+vJTdUKLbGZhBd+wHHLrhCT67pQh0MOKw6VKzZb960CYpRc9e2bMQj/FLfxI83EkKl8+IJLPD/c3NA+JFe0RsTXni2Fyjrj8l5MDODnETC2iMPm5+1H08QnX31p8BEckrv86ilQrVrOQEMN",
       @"DisconnectTimeout": @30,
       @"KeepAliveTimeout": @20,
       @"LongPollDelay": @0,
       @"ProtocolVersion": @"1.3.0.0",
       @"TransportConnectTimeout": @5,
       @"TryWebSockets": @YES,
       @"Url": @"/signalr"
   }];
}

+ (id <UMKMockURLResponder>)negotiateForTransport:(id <SRClientTransportInterface>)transport
                                        responder:(id <UMKMockURLResponder>)responder {
    return [self expectMockRequestWithHTTPMethod:@"GET" path:@"negotiate" responder:responder];
}

+ (id <UMKMockURLResponder>)negotiateForTransport:(id <SRClientTransportInterface>)transport
                                       statusCode:(NSNumber *)statusCode
                                             json:(id)json; {
    UMKMockHTTPResponder * responder = [UMKMockHTTPResponder mockHTTPResponderWithStatusCode:[statusCode integerValue]];
    if (json) {
        [responder setBodyWithJSONObject:json];
    }
    return [self negotiateForTransport:transport responder:responder];
}

+ (id <UMKMockURLResponder>)negotiateForTransport:(id <SRClientTransportInterface>)transport
                                       statusCode:(NSNumber *)statusCode
                                            error:(NSError *)error {
    UMKMockHTTPResponder * responder = [UMKMockHTTPResponder mockHTTPResponderWithError:error];
    return [self negotiateForTransport:transport responder:responder];
}

#pragma mark -
#pragma mark Start

+ (id <UMKMockURLResponder>)connectTransport:(id <SRClientTransportInterface>)transport
                                   responder:(id <UMKMockURLResponder>)responder; {
    return [self expectMockRequestWithHTTPMethod:@"GET" path:@"connect" responder:responder];
}

+ (id <UMKMockURLResponder>)connectTransport:(id <SRClientTransportInterface>)transport
                                  statusCode:(NSNumber *)statusCode
                                       error:(NSError *)error; {
    UMKMockHTTPResponder * responder = [UMKMockHTTPResponder mockHTTPResponderWithError:error];
    return [self connectTransport:transport responder:responder];
}

+ (id <UMKMockURLResponder>)reconnectTransport:(id <SRClientTransportInterface>)transport
                                     responder:(id <UMKMockURLResponder>)responder; {
    return [self expectMockRequestWithHTTPMethod:@"GET" path:@"reconnect" responder:responder];
}

+ (id <UMKMockURLResponder>)reconnectTransport:(id <SRClientTransportInterface>)transport
                                    statusCode:(NSNumber *)statusCode
                                         error:(NSError *)error; {
    UMKMockHTTPResponder * responder = [UMKMockHTTPResponder mockHTTPResponderWithError:error];
    return [self reconnectTransport:transport responder:responder];
}

#pragma mark -
#pragma mark Send

+ (id <UMKMockURLResponder>)sendForTransport:(id <SRClientTransportInterface>)transport
                                   responder:(id <UMKMockURLResponder>)responder {
    return [self expectMockRequestWithHTTPMethod:@"POST" path:@"send" responder:responder];
}

+ (id <UMKMockURLResponder>)sendForTransport:(id <SRClientTransportInterface>)transport
                                  statusCode:(NSNumber *)statusCode
                                        json:(id)json; {
    UMKMockHTTPResponder * responder = [UMKMockHTTPResponder mockHTTPResponderWithStatusCode:[statusCode integerValue]];
    if (json) {
        [responder setBodyWithJSONObject:json];
    }
    return [self sendForTransport:transport responder:responder];
}

+ (id <UMKMockURLResponder>)sendForTransport:(id <SRClientTransportInterface>)transport
                                  statusCode:(NSNumber *)statusCode
                                       error:(NSError *)error {
    UMKMockHTTPResponder * responder = [UMKMockHTTPResponder mockHTTPResponderWithError:error];
    return [self sendForTransport:transport responder:responder];
}

#pragma mark -
#pragma mark abort

+ (id <UMKMockURLResponder>)abortForTransport:(id <SRClientTransportInterface>)transport
                                    responder:(id <UMKMockURLResponder>)responder {
    return [self expectMockRequestWithHTTPMethod:@"POST" path:@"abort" responder:responder];
}

+ (id <UMKMockURLResponder>)abortForTransport:(id <SRClientTransportInterface>)transport
                                   statusCode:(NSNumber *)statusCode
                                         json:(id)json; {
    UMKMockHTTPResponder * responder = [UMKMockHTTPResponder mockHTTPResponderWithStatusCode:[statusCode integerValue]];
    if (json) {
        [responder setBodyWithJSONObject:json];
    }
    return [self abortForTransport:transport responder:responder];
}

+ (id <UMKMockURLResponder>)abortForTransport:(id <SRClientTransportInterface>)transport
                                   statusCode:(NSNumber *)statusCode
                                        error:(NSError *)error {
    UMKMockHTTPResponder * responder = [UMKMockHTTPResponder mockHTTPResponderWithError:error];
    return [self abortForTransport:transport responder:responder];
}

@end
