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
#import "SRMockClientTransport.h"

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
    [SRMockClientTransport startForMockTransport:transport statusCode:@400 error:[[NSError alloc]initWithDomain:@"Expected" code:42 userInfo:nil]];
    id json = @{
        @"ConnectionId": @"10101",
        @"ConnectionToken": @"10101010101",
        @"DisconnectTimeout": @30,
        @"ProtocolVersion": @"1.3.0.0"
    };
    [SRMockClientTransport negotiateForMockTransport:transport statusCode:@200 json:json];

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

- (void) testTransportErrorCausesClosed
{
    id transport = [OCMockObject niceMockForProtocol:@protocol(SRClientTransportInterface)];
    [SRMockClientTransport startForMockTransport:transport statusCode:@400 error:[[NSError alloc]initWithDomain:@"Expected" code:42 userInfo:nil]];
    id json = @{
                @"ConnectionId": @"10101",
                @"ConnectionToken": @"10101010101",
                @"DisconnectTimeout": @30,
                @"ProtocolVersion": @"1.3.0.0"
                };
    [SRMockClientTransport negotiateForMockTransport:transport statusCode:@200 json:json];

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

- (void) testTransportNegotiateCausesError
{
    id transport = [OCMockObject niceMockForProtocol:@protocol(SRClientTransportInterface)];
    [SRMockClientTransport negotiateForMockTransport:transport statusCode:@400 error:[NSError errorWithDomain:@"UNIT TEST" code:NSURLErrorTimedOut userInfo:nil]];

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
    [SRMockClientTransport negotiateForMockTransport:transport statusCode:@400 error:[NSError errorWithDomain:@"UNIT TEST" code:NSURLErrorTimedOut userInfo:nil]];

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

- (void)testConnectionCanRestartAfterNegotiateError {
    id failingTransport = [OCMockObject niceMockForProtocol:@protocol(SRClientTransportInterface)];
    [SRMockClientTransport negotiateForMockTransport:failingTransport statusCode:@400 error:[NSError errorWithDomain:@"UNIT TEST" code:NSURLErrorTimedOut userInfo:nil]];
    
    id successTransport = [OCMockObject niceMockForProtocol:@protocol(SRClientTransportInterface)];
    [[successTransport expect] negotiate:[OCMArg any] connectionData:[OCMArg any] completionHandler:[OCMArg any]];
    
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    [connection start: failingTransport];
    XCTAssertEqual(connection.state, disconnected);
    [connection start: successTransport];
    XCTAssertEqual(connection.state, connecting);
    [successTransport verify];
    
}

- (void)testConnectionCanRestartAfterStartError {
    id failingTransport = [OCMockObject niceMockForProtocol:@protocol(SRClientTransportInterface)];
    [SRMockClientTransport startForMockTransport:failingTransport statusCode:@400 error:[[NSError alloc]initWithDomain:@"Expected" code:42 userInfo:nil]];
    id json = @{
        @"ConnectionId": @"10101",
        @"ConnectionToken": @"10101010101",
        @"DisconnectTimeout": @30,
        @"ProtocolVersion": @"1.3.0.0"
    };
    [SRMockClientTransport negotiateForMockTransport:failingTransport statusCode:@200 json:json];
    
    id successTransport = [OCMockObject niceMockForProtocol:@protocol(SRClientTransportInterface)];
    [SRMockClientTransport negotiateForMockTransport:successTransport statusCode:@200 json:json];
    [[successTransport expect] start:[OCMArg any] connectionData:[OCMArg any] completionHandler:[OCMArg any]];
    
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    [connection start: failingTransport];
    XCTAssertEqual(connection.state, disconnected);
    [connection start: successTransport];
    XCTAssertEqual(connection.state, connecting);
    [successTransport verify];
    
}

@end
