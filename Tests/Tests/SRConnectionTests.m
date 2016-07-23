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
#import "SRMockClientTransport+OCMock.h"

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
    [SRMockClientTransport negotiateForMockTransport:transport];
    [SRMockClientTransport startForMockTransport:transport statusCode:@400 error:[[NSError alloc]initWithDomain:@"Expected" code:42 userInfo:nil]];

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
    [SRMockClientTransport negotiateForMockTransport:transport];
    [SRMockClientTransport startForMockTransport:transport statusCode:@400 error:[[NSError alloc]initWithDomain:@"Expected" code:42 userInfo:nil]];

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
    [SRMockClientTransport negotiateForMockTransport:failingTransport];
    [SRMockClientTransport startForMockTransport:failingTransport statusCode:@400 error:[[NSError alloc]initWithDomain:@"Expected" code:42 userInfo:nil]];

    id successTransport = [OCMockObject niceMockForProtocol:@protocol(SRClientTransportInterface)];
    [SRMockClientTransport negotiateForMockTransport:successTransport];
    [[successTransport expect] start:[OCMArg any] connectionData:[OCMArg any] completionHandler:[OCMArg any]];
    
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    [connection start: failingTransport];
    XCTAssertEqual(connection.state, disconnected);
    [connection start: successTransport];
    XCTAssertEqual(connection.state, connecting);
    [successTransport verify];
    
}

- (void)testTransportThrowsAnErrorIfProtocolVersionIsIncorrect{
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    id transport = [OCMockObject niceMockForProtocol:@protocol(SRClientTransportInterface)];
    id json = @{
        @"ConnectionId": @"10101",
        @"ConnectionToken": @"10101010101",
        @"DisconnectTimeout": @30,
        @"ProtocolVersion": @"2.0.0.0",
        @"TransportConnectTimeout": @10
    };
    [SRMockClientTransport negotiateForMockTransport:transport statusCode:@200 json:json];
    XCTAssertThrows([connection start:transport]);
}

- (void)testConnectionCanBeStoppedPriorToTransportStart {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    id transport = [OCMockObject niceMockForProtocol:@protocol(SRClientTransportInterface)];
    [[[transport stub] andDo:^(NSInvocation *invocation) {
        __unsafe_unretained void (^ callbackOut)(SRNegotiationResponse * response, NSError *error);
        [invocation getArgument: &callbackOut atIndex: 4];
        //do not respond to negotiate!!
        //we will stop the connection before its completion
    }] negotiate:[OCMArg any] connectionData:[OCMArg any] completionHandler:[OCMArg any]];
    
    connection.started = ^(){
        XCTAssert(NO, @"start was triggered");
    };
    
    XCTestExpectation *closed = [self expectationWithDescription:@"closed"];
    connection.closed = ^{
        [closed fulfill];
    };
    
    connection.error = ^(NSError* err){
        XCTAssert(NO, @"Error was triggered");
    };
    
    [connection start:transport];
    [connection stop];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)xtestTransportAutoJSONEncodesMessagesCorrectlyWhenSending {
    // This is an example of a functional test case.
    XCTAssert(NO, @"not implemented");
}

@end
