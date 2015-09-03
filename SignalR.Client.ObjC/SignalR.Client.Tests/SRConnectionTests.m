//
//  SRConnectionTests.m
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 8/3/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SRConnection.h"
#import "SRVersion.h"
#import "SRClientTransportInterface.h"
#import "SRNegotiationResponse.h"

@interface SRConnectionTests : XCTestCase

@end

@implementation SRConnectionTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void) testTransportErrorCausesError
{
    id transport = [OCMockObject niceMockForProtocol:@protocol(SRClientTransportInterface)];
    __block void(^done)(id response, NSError *error);
    [[[transport stub] andDo:^(NSInvocation *invocation) {
        __unsafe_unretained void (^callbackOut)(id response, NSError* err);
        [invocation getArgument: &callbackOut atIndex: 4];
        done = callbackOut;
    }] start:[OCMArg any] connectionData:[OCMArg any] completionHandler:[OCMArg any]];
    [[[transport stub] andDo:^(NSInvocation *invocation) {
        __unsafe_unretained void (^successCallback)(SRNegotiationResponse *, NSError *) = nil;
        [invocation getArgument: &successCallback atIndex: 4];
        successCallback([[SRNegotiationResponse alloc ]
                         initWithDictionary:@{
                                              @"ConnectionId": @"10101",
                                              @"ConnectionToken": @"10101010101",
                                              @"DisconnectTimeout": @30,
                                              @"ProtocolVersion": @"1.3.0.0"
                                              }], nil);
    }] negotiate:[OCMArg any] connectionData:[OCMArg any] completionHandler:[OCMArg any]];
    
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    id willErrorOnError = [self expectationWithDescription:@"gets closed when transport errors out"];
    connection.error = ^(NSError *error){
        [willErrorOnError fulfill];
    };
    [connection start: transport];
    done(nil, [[NSError alloc]initWithDomain:@"Expected" code:42 userInfo:nil]);
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error){
            NSLog(@"Sub-Timeout Error: %@", error);
        }
    }];
}

- (void) testTransportErrorCausesClosed
{
    id transport = [OCMockObject niceMockForProtocol:@protocol(SRClientTransportInterface)];
    __block void(^done)(id response, NSError *error);
    [[[transport stub] andDo:^(NSInvocation *invocation) {
        __unsafe_unretained void (^callbackOut)(id response, NSError* err);
        [invocation getArgument: &callbackOut atIndex: 4];
        done = callbackOut;
    }] start:[OCMArg any] connectionData:[OCMArg any] completionHandler:[OCMArg any]];
    [[[transport stub] andDo:^(NSInvocation *invocation) {
        __unsafe_unretained void (^successCallback)(SRNegotiationResponse *, NSError *) = nil;
        [invocation getArgument: &successCallback atIndex: 4];
        successCallback([[SRNegotiationResponse alloc ]
                     initWithDictionary:@{
                                          @"ConnectionId": @"10101",
                                          @"ConnectionToken": @"10101010101",
                                          @"DisconnectTimeout": @30,
                                          @"ProtocolVersion": @"1.3.0.0"
                                          }], nil);
    }] negotiate:[OCMArg any] connectionData:[OCMArg any] completionHandler:[OCMArg any]];
    
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    id willCloseOnError = [self expectationWithDescription:@"gets closed when transport errors out"];
    connection.closed = ^{
        [willCloseOnError fulfill];
    };
    [connection start: transport];
    done(nil, [[NSError alloc]initWithDomain:@"Expected" code:42 userInfo:nil]);
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error){
            NSLog(@"Sub-Timeout Error: %@", error);
        }
    }];
}

- (void) testTransportNegotiateCausesError
{
    id transport = [OCMockObject niceMockForProtocol:@protocol(SRClientTransportInterface)];
    
    [[[transport stub] andDo:^(NSInvocation *invocation) {
        __unsafe_unretained void (^successCallback)(SRNegotiationResponse *, NSError *) = nil;
        [invocation getArgument: &successCallback atIndex: 4];
        successCallback(nil, [NSError errorWithDomain:@"UNIT TEST" code:NSURLErrorTimedOut userInfo:nil]);
    }] negotiate:[OCMArg any] connectionData:[OCMArg any] completionHandler:[OCMArg any]];
    
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    id willErrorOnError = [self expectationWithDescription:@"gets closed when transport errors out"];
    connection.error = ^(NSError *error){
        [willErrorOnError fulfill];
    };
    [connection start: transport];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error){
            NSLog(@"Sub-Timeout Error: %@", error);
        }
    }];
}

- (void) testTransportNegotiateCausesClosed
{
    id transport = [OCMockObject niceMockForProtocol:@protocol(SRClientTransportInterface)];

    [[[transport stub] andDo:^(NSInvocation *invocation) {
        __unsafe_unretained void (^successCallback)(SRNegotiationResponse *, NSError *) = nil;
        [invocation getArgument: &successCallback atIndex: 4];
        successCallback(nil, [NSError errorWithDomain:@"UNIT TEST" code:NSURLErrorTimedOut userInfo:nil]);
    }] negotiate:[OCMArg any] connectionData:[OCMArg any] completionHandler:[OCMArg any]];
    
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    id willCloseOnError = [self expectationWithDescription:@"gets closed when transport errors out"];
    connection.closed = ^{
        [willCloseOnError fulfill];
    };
    [connection start: transport];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error){
            NSLog(@"Sub-Timeout Error: %@", error);
        }
    }];
}

@end
