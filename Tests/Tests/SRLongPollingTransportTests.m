//
//  SRLongPollingTransport.m
//  SignalR.Client.ObjC
//
//  Created by Joel Dart on 8/4/15.
//  Copyright (c) 2015 DyKnow LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SRConnection.h"
#import "SRLongPollingTransport.h"
#import "SRMockClientTransport+LP.h"
#import "SRMockClientTransport+OCMock.h"
#import "SRMockWaitBlockOperation.h"
#import "SRBlockOperation.h"
#import "SRMockLPResponder.h"

@interface SRLongPollingTransportTests : XCTestCase

@end

@implementation SRLongPollingTransportTests

- (void)setUp {
    [super setUp];
    [UMKMockURLProtocol enable];
    [UMKMockURLProtocol reset];
}

- (void)tearDown {
    [UMKMockURLProtocol disable];
    [super tearDown];
}

- (void)testHasCorrectTransportName {
    SRLongPollingTransport* lp = [SRMockLPTransport transport];
    XCTAssert([[lp name] isEqualToString:@"longPolling"]);
}

- (void)testSupportsKeepAlive {
    SRLongPollingTransport* lp = [SRMockLPTransport transport];
    XCTAssertFalse([lp supportsKeepAlive]);
}

- (void)testDefaultReconnectDelay {
    SRLongPollingTransport* lp = [SRMockLPTransport transport];
    XCTAssertEqual([lp reconnectDelay], @5);
}

- (void)testDefaultErrorDelay {
    SRLongPollingTransport* lp = [SRMockLPTransport transport];
    XCTAssertEqual([lp errorDelay], @2);
}

@end

@implementation SRLongPollingTransportTests (MessageParsing)

- (void)testParsesMessages {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRLongPollingTransport* lp = [SRMockLPTransport transport];
    [SRMockLPTransport negotiateForTransport:lp];
    [SRMockLPTransport connectTransport:lp statusCode:@200 json:@{
        @"C": @"1",
        @"M":@[ @{
            @"H":@"hubname",
            @"M":@"message",
            @"A":@"blah"
        } ]
    }];
    
    __weak XCTestExpectation *received = [self expectationWithDescription:@"received"];
    connection.received = ^(NSDictionary * data){
        if ([[data valueForKey:@"M"] isEqualToString:@"message"]
            && [[data valueForKey:@"H"] isEqualToString:@"hubname"]
            && [[data valueForKey:@"A"] isEqualToString:@"blah"]) {
            [received fulfill];
        }
    };
    
    [connection start:lp];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testConnectionDisconnectsWhenServerDisconnectReceived {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRLongPollingTransport* lp = [SRMockLPTransport transport];
    [SRMockLPTransport negotiateForTransport:lp];
    [SRMockLPTransport connectTransport:lp statusCode:@200 json:@{
        @"D": @YES
    }];
    
    __weak XCTestExpectation *closed = [self expectationWithDescription:@"closed"];
    connection.closed = ^(){
        [closed fulfill];
    };
    
    [connection start:lp];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testConnectionReconnectsWhenServerReconnectReceivedDuringInitialConnect {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRLongPollingTransport* lp = [SRMockLPTransport transport];
    [SRMockLPTransport negotiateForTransport:lp];
    [SRMockLPTransport connectTransport:lp statusCode:@200 json:@{
        @"C": @"1",
        @"T": @YES,
        @"M":@[ @{
            @"H":@"hubname",
            @"M":@"message",
            @"A":@"12345"
        } ]
    }];
    [SRMockLPTransport reconnectTransport:lp statusCode:@200 json:@{
        @"C": @"2",
        @"M":@[ @{
            @"H":@"hubname",
            @"M":@"message",
            @"A":@"67890"
        } ]
    }];
    
    __weak XCTestExpectation *started = [self expectationWithDescription:@"started"];
    connection.started = ^{
        [started fulfill];
    };
    
    __weak XCTestExpectation *reconnecting = [self expectationWithDescription:@"reconnecting"];
    connection.reconnecting = ^(){
        [reconnecting fulfill];
    };
    
    __weak XCTestExpectation *reconnected = [self expectationWithDescription:@"reconnected"];
    connection.reconnected = ^(){
        [reconnected fulfill];
    };
    
    connection.error = ^(NSError *error){
        XCTFail(@"connection errored");
    };
    
    connection.closed = ^{
        XCTFail(@"connection closed");
    };
    
    [connection start:lp];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testConnectionReconnectsWhenServerReconnectReceived {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRLongPollingTransport* lp = [SRMockLPTransport transport];
    [SRMockLPTransport negotiateForTransport:lp];
    [SRMockLPTransport connectTransport:lp statusCode:@200 json:@{
        @"C": @"1",
        @"M":@[ @{
            @"H":@"hubname",
            @"M":@"message",
            @"A":@"12345"
        } ]
    }];
    [SRMockLPTransport pollTransport:lp statusCode:@200 json:@{
        @"C": @"2",
        @"T": @YES
    }];
    [SRMockLPTransport reconnectTransport:lp statusCode:@200 json:@{
        @"C": @"3",
        @"M":@[ @{
            @"H":@"hubname",
            @"M":@"message",
            @"A":@"67890"
        } ]
    }];
    
    __weak XCTestExpectation *started = [self expectationWithDescription:@"started"];
    connection.started = ^{
        [started fulfill];
    };
    
    __weak XCTestExpectation *reconnecting = [self expectationWithDescription:@"reconnecting"];
    connection.reconnecting = ^(){
        [reconnecting fulfill];
    };
    
    __weak XCTestExpectation *reconnected = [self expectationWithDescription:@"reconnected"];
    connection.reconnected = ^(){
        [reconnected fulfill];
    };
    
    connection.error = ^(NSError *error){
        XCTFail(@"connection errored");
    };
    
    connection.closed = ^{
        XCTFail(@"connection closed");
    };
    
    [connection start:lp];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end

@implementation SRLongPollingTransportTests (Negotiate)

@end

@implementation SRLongPollingTransportTests (Initialize)

- (void)testPollingInitializesSuccessfully {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRLongPollingTransport* lp = [SRMockLPTransport transport];
    [SRMockLPTransport negotiateForTransport:lp];
    [SRMockLPTransport connectTransport:lp statusCode:@200 json:@{
        @"C": @"1",
        @"M":@[ @{
            @"H":@"hubname",
            @"M":@"message",
            @"A":@"12345"
        } ]
    }];
    
    __weak XCTestExpectation *started = [self expectationWithDescription:@"started"];
    connection.started = ^{
        [started fulfill];
    };
    
    connection.reconnecting = ^(){
        XCTFail(@"connection reconnecting");
    };
    
    connection.reconnected = ^(){
        XCTFail(@"connection reconnected");
    };
    
    connection.error = ^(NSError *error){
        XCTFail(@"connection errored");
    };
    
    connection.closed = ^{
        XCTFail(@"connection closed");
    };
    
    [connection start:lp];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testPollingClosesWithErrorDuringConnect {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRLongPollingTransport* lp = [SRMockLPTransport transport];
    [SRMockLPTransport negotiateForTransport:lp];
    [SRMockLPTransport connectTransport:lp statusCode:@400 error:[[NSError alloc] initWithDomain:@"EXPECTED" code:NSURLErrorUnknown userInfo:nil]];
    
    connection.started = ^{
        XCTFail(@"connection started");
    };
    
    connection.reconnecting = ^(){
        XCTFail(@"connection reconnecting");
    };
    
    connection.reconnected = ^(){
        XCTFail(@"connection reconnected");
    };
    
    __weak XCTestExpectation *errored = [self expectationWithDescription:@"errored"];
    connection.error = ^(NSError *error){
        [errored fulfill];
    };
    
    connection.closed = ^{
        XCTFail(@"connection closed");
    };
    
    [connection start:lp];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testPollingFirstClosesWithErrorThenSucceedsDuringConnect {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRLongPollingTransport* lp = [SRMockLPTransport transport];
    [SRMockLPTransport negotiateForTransport:lp];
    [SRMockLPTransport connectTransport:lp statusCode:@400 error:[[NSError alloc] initWithDomain:@"EXPECTED" code:NSURLErrorUnknown userInfo:nil]];
    
    __weak XCTestExpectation *started = [self expectationWithDescription:@"started"];
    connection.started = ^{
        [started fulfill];
    };
    
    connection.reconnecting = ^(){
        XCTFail(@"connection reconnecting");
    };
    
    connection.reconnected = ^(){
        XCTFail(@"connection reconnected");
    };
    
    __weak XCTestExpectation *errored = [self expectationWithDescription:@"errored"];
    connection.error = ^(NSError *error){
        [errored fulfill];
        [UMKMockURLProtocol reset];
        [SRMockLPTransport connectTransport:lp statusCode:@200 json:@{
          @"C": @"1",
          @"M":@[ @{
              @"H":@"hubname",
              @"M":@"message",
              @"A":@"12345"
          } ]
        }];
        [SRMockLPTransport pollTransport:lp statusCode:@200 json:@{
           @"C": @"2",
           @"M":@[ @{
               @"H":@"hubname",
               @"M":@"message",
               @"A":@"67890"
           } ]
       }];
    };
    
    connection.closed = ^{
        XCTFail(@"connection closed");
    };
    
    [connection start:lp];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testPollingClosesWithCancelledDuringConnect {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRLongPollingTransport* lp = [SRMockLPTransport transport];
    [SRMockLPTransport negotiateForTransport:lp];
    [SRMockLPTransport connectTransport:lp statusCode:@400 error:[[NSError alloc] initWithDomain:@"EXPECTED" code:NSURLErrorCancelled userInfo:nil]];
    
    connection.started = ^{
        XCTFail(@"connection started");
    };
    
    connection.reconnecting = ^(){
        XCTFail(@"connection reconnecting");
    };
    
    connection.reconnected = ^(){
        XCTFail(@"connection reconnected");
    };
    
    connection.error = ^(NSError *error){
        XCTFail(@"connection errored");
    };
    
    __weak XCTestExpectation *closed = [self expectationWithDescription:@"closed"];
    connection.closed = ^{
        [closed fulfill];
    };
    
    [connection start:lp];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testConnectionStoppedBeforeConnectCompletes {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRLongPollingTransport* lp = [SRMockLPTransport transport];
    [SRMockLPTransport negotiateForTransport:lp];
    __weak __typeof(&*connection)weakConnection = connection;
    [[SRMockLPTransport connectTransport:lp statusCode:@0 json:@{}] beforeData:^(NSData * _Nonnull data) {
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        [strongConnection stop];
    }];
    
    connection.started = ^(){
        XCTFail(@"connection started");
    };
    
    connection.reconnecting = ^(){
        XCTFail(@"connection reconnecting");
    };
    
    connection.reconnected = ^(){
        XCTFail(@"connection reconnected");
    };
    
    connection.error = ^(NSError* err){
        XCTFail(@"connection error");
    };
    
    __weak XCTestExpectation *closed = [self expectationWithDescription:@"closed"];
    connection.closed = ^{
        [closed fulfill];
    };
    
    [connection start:lp];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    
}

- (void)testConnectionStoppedAfterConnectCompletes {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRLongPollingTransport* lp = [SRMockLPTransport transport];
    [SRMockLPTransport negotiateForTransport:lp];
    __weak __typeof(&*connection)weakConnection = connection;
    [[SRMockLPTransport connectTransport:lp statusCode:@200 json:@{
        @"C": @"1",
        @"M":@[ @{
            @"H":@"hubname",
            @"M":@"message",
            @"A":@"12345"
        } ]
    }] afterEnd:^(NSError * _Nullable error) {
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        [strongConnection stop];
    }];
    
    __weak XCTestExpectation *started = [self expectationWithDescription:@"started"];
    connection.started = ^(){
        [started fulfill];
    };
    
    connection.reconnecting = ^(){
        XCTFail(@"connection reconnecting");
    };
    
    connection.reconnected = ^(){
        XCTFail(@"connection reconnected");
    };
    
    connection.error = ^(NSError* err){
        XCTFail(@"connection error");
    };
    
    __weak XCTestExpectation *closed = [self expectationWithDescription:@"closed"];
    connection.closed = ^{
        [closed fulfill];
    };
    
    [connection start:lp];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testConnectionStoppedAndRestartedBeforeConnectCompletes {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRLongPollingTransport* lp1 = [SRMockLPTransport transport];
    [SRMockLPTransport negotiateForTransport:lp1];
    __weak __typeof(&*connection)weakConnection = connection;
    [[SRMockLPTransport connectTransport:lp1 statusCode:@0 json:@{}] beforeData:^(NSData * _Nonnull data) {
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        [strongConnection stop];
    }];
    [SRMockLPTransport abortForTransport:lp1 statusCode:@200 json:@{}];
    
    __weak XCTestExpectation *started = [self expectationWithDescription:@"started"];
    connection.started = ^{
        [started fulfill];
    };
    
    connection.reconnecting = ^(){
        XCTFail(@"connection reconnecting");
    };
    
    connection.reconnected = ^(){
        XCTFail(@"connection reconnected");
    };
    
    connection.error = ^(NSError* err){
        XCTFail(@"connection errored");
    };
    
    __weak XCTestExpectation *closed = [self expectationWithDescription:@"closed"];
    connection.closed = ^{
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        [closed fulfill];
        [UMKMockURLProtocol reset];
        SRLongPollingTransport* lp2 = [SRMockLPTransport transport];
        [SRMockLPTransport negotiateForTransport:lp2];
        [SRMockLPTransport connectTransport:lp2 statusCode:@200 json:@{}];
        [strongConnection start:lp2];
    };
    
    [connection start:lp1];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testConnectionStoppedAndRestartedAfterConnectCompletes {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRLongPollingTransport* lp1 = [SRMockLPTransport transport];
    [SRMockLPTransport negotiateForTransport:lp1];
    __weak __typeof(&*connection)weakConnection = connection;
    [[SRMockLPTransport connectTransport:lp1 statusCode:@200 json:@{
        @"C": @"1",
        @"M":@[ @{
            @"H":@"hubname",
            @"M":@"message",
            @"A":@"12345"
        } ]
    }] afterEnd:^(NSError * _Nullable error) {
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        [strongConnection stop];
    }];
    [SRMockLPTransport abortForTransport:lp1 statusCode:@200 json:@{}];
    
    __block NSInteger startCount = 0;
    __weak XCTestExpectation *started = [self expectationWithDescription:@"closed"];
    connection.started = ^{
        startCount++;
        if (startCount == 2) {
            [started fulfill];
        }
    };
    
    connection.reconnecting = ^(){
        XCTFail(@"connection reconnecting");
    };
    
    connection.reconnected = ^(){
        XCTFail(@"connection reconnected");
    };
    
    connection.error = ^(NSError* err){
        XCTFail(@"connection errored");
    };
    
    __weak XCTestExpectation *closed = [self expectationWithDescription:@"closed"];
    connection.closed = ^{
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        [closed fulfill];
        [UMKMockURLProtocol reset];
        SRLongPollingTransport* lp2 = [SRMockLPTransport transport];
        [SRMockLPTransport negotiateForTransport:lp2];
        [SRMockLPTransport connectTransport:lp2 statusCode:@200 json:@{
            @"C": @"2",
            @"M":@[ @{
                @"H":@"hubname",
                @"M":@"message",
                @"A":@"12345"
            } ]
        }];
        [strongConnection start:lp2];
    };
    
    [connection start:lp1];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end

@implementation SRLongPollingTransportTests (Reconnect)

- (void)testPollingClosesWithErrorDuringReconnect {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRLongPollingTransport* lp = [SRMockLPTransport transport];
    [SRMockLPTransport negotiateForTransport:lp];
    [SRMockLPTransport connectTransport:lp statusCode:@200 json:@{
        @"C": @"1",
        @"T": @YES,
        @"M":@[ @{
            @"H":@"hubname",
            @"M":@"message",
            @"A":@"12345"
        } ]
    }];
    [SRMockLPTransport reconnectTransport:lp statusCode:@400 error:[[NSError alloc] initWithDomain:@"EXPECTED" code:NSURLErrorUnknown userInfo:nil]];
    
    __weak XCTestExpectation *started = [self expectationWithDescription:@"started"];
    connection.started = ^{
        [started fulfill];
    };
    
    __weak XCTestExpectation *reconnecting = [self expectationWithDescription:@"reconnecting"];
    connection.reconnecting = ^(){
        [reconnecting fulfill];
    };
    
    connection.reconnected = ^(){
        XCTFail(@"connection reconnected");
    };
    
    __weak XCTestExpectation *errored = [self expectationWithDescription:@"errored"];
    connection.error = ^(NSError *error){
        [errored fulfill];
    };
    
    connection.closed = ^{
        XCTFail(@"connection closed");
    };
    
    [connection start:lp];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testPollingClosesWithCancelledDuringReconnect {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRLongPollingTransport* lp = [SRMockLPTransport transport];
    [SRMockLPTransport negotiateForTransport:lp];
    [SRMockLPTransport connectTransport:lp statusCode:@200 json:@{
        @"C": @"1",
        @"T": @YES,
        @"M":@[ @{
            @"H":@"hubname",
            @"M":@"message",
            @"A":@"12345"
        } ]
    }];
    [SRMockLPTransport reconnectTransport:lp statusCode:@400 error:[[NSError alloc] initWithDomain:@"EXPECTED" code:NSURLErrorCancelled userInfo:nil]];
    
    __weak XCTestExpectation *started = [self expectationWithDescription:@"started"];
    connection.started = ^{
        [started fulfill];
    };
    
    __weak XCTestExpectation *reconnecting = [self expectationWithDescription:@"reconnecting"];
    connection.reconnecting = ^(){
        [reconnecting fulfill];
    };
    
    connection.reconnected = ^(){
        XCTFail(@"connection reconnected");
    };
    
    connection.error = ^(NSError *error){
        XCTFail(@"connection errored");
    };
    
    connection.closed = ^{
        XCTFail(@"connection closed");
    };
    
    [connection start:lp];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testConnectionStoppedBeforeReconnectCompletes {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRLongPollingTransport* lp = [SRMockLPTransport transport];
    [SRMockLPTransport negotiateForTransport:lp];
    [SRMockLPTransport connectTransport:lp statusCode:@200 json:@{
        @"C": @"1",
        @"T": @YES,
        @"M":@[ @{
            @"H":@"hubname",
            @"M":@"message",
            @"A":@"12345"
        } ]
    }];
    __weak __typeof(&*connection)weakConnection = connection;
    [[SRMockLPTransport reconnectTransport:lp statusCode:@0 json:@{}] beforeData:^(NSData * _Nonnull data) {
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        [strongConnection stop];
    }];
    __weak XCTestExpectation *started = [self expectationWithDescription:@"started"];
    connection.started = ^{
        [started fulfill];
    };
    
    __weak XCTestExpectation *reconnecting = [self expectationWithDescription:@"reconnecting"];
    connection.reconnecting = ^(){
        [reconnecting fulfill];
    };
    
    connection.reconnected = ^(){
        XCTFail(@"connection reconnected");
    };
    
    connection.error = ^(NSError *error){
        XCTFail(@"connection errored");
    };
    
    __weak XCTestExpectation *closed = [self expectationWithDescription:@"closed"];
    connection.closed = ^{
        [closed fulfill];
    };
    
    [connection start:lp];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testConnectionStoppedAfterReconnectCompletes {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRLongPollingTransport* lp = [SRMockLPTransport transport];
    [SRMockLPTransport negotiateForTransport:lp];
    [SRMockLPTransport connectTransport:lp statusCode:@200 json:@{
        @"C": @"1",
        @"T": @YES,
        @"M":@[ @{
            @"H":@"hubname",
            @"M":@"message",
            @"A":@"12345"
        } ]
    }];
    __weak __typeof(&*connection)weakConnection = connection;
    [[SRMockLPTransport reconnectTransport:lp statusCode:@200 json:@{
        @"C": @"2",
        @"M":@[ @{
            @"H":@"hubname",
            @"M":@"message",
            @"A":@"67890"
        } ]
    }] afterEnd:^(NSError * _Nullable error) {
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        [strongConnection stop];
    }];
    
    __weak XCTestExpectation *started = [self expectationWithDescription:@"started"];
    connection.started = ^{
        [started fulfill];
    };
    
    __weak XCTestExpectation *reconnecting = [self expectationWithDescription:@"reconnecting"];
    connection.reconnecting = ^(){
        [reconnecting fulfill];
    };
    
    __weak XCTestExpectation *reconnected = [self expectationWithDescription:@"reconnected"];
    connection.reconnected = ^(){
        [reconnected fulfill];
    };
    
    connection.error = ^(NSError *error){
        XCTFail(@"connection errored");
    };
    
    __weak XCTestExpectation *closed = [self expectationWithDescription:@"closed"];
    connection.closed = ^{
        [closed fulfill];
    };
    
    [connection start:lp];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testConnectionStoppedAndRestartedBeforeReconnectCompletes {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRLongPollingTransport* lp1 = [SRMockLPTransport transport];
    [SRMockLPTransport negotiateForTransport:lp1];
    __weak __typeof(&*connection)weakConnection = connection;
    [SRMockLPTransport connectTransport:lp1 statusCode:@200 json:@{
        @"C": @"1",
        @"T": @YES,
        @"M":@[ @{
            @"H":@"hubname",
            @"M":@"message",
            @"A":@"12345"
        } ]
    }];
    [SRMockLPTransport abortForTransport:lp1 statusCode:@200 json:@{}];
    [[SRMockLPTransport reconnectTransport:lp1 statusCode:@0 json:@{}] beforeData:^(NSData * _Nonnull data) {
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        [strongConnection stop];
    }];
    
    __weak XCTestExpectation *started = [self expectationWithDescription:@"started"];
    connection.started = ^{
        [started fulfill];
    };
    
    __weak XCTestExpectation *reconnecting = [self expectationWithDescription:@"reconnecting"];
    connection.reconnecting = ^(){
        [reconnecting fulfill];
    };
    
    connection.reconnected = ^(){
        XCTFail(@"connection reconnected");
    };
    
    connection.error = ^(NSError* err){
        XCTFail(@"connection errored");
    };
    
    __weak XCTestExpectation *closed = [self expectationWithDescription:@"closed"];
    connection.closed = ^{
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        [closed fulfill];
        [UMKMockURLProtocol reset];
        SRLongPollingTransport* lp2 = [SRMockLPTransport transport];
        [SRMockLPTransport negotiateForTransport:lp2];
        [SRMockLPTransport connectTransport:lp2 statusCode:@200 json:@{}];
        [strongConnection start:lp2];
    };
    
    [connection start:lp1];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testConnectionStoppedAndRestartedAfterReconnectCompletes {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRLongPollingTransport* lp1 = [SRMockLPTransport transport];
    [SRMockLPTransport negotiateForTransport:lp1];
    __weak __typeof(&*connection)weakConnection = connection;
    [SRMockLPTransport connectTransport:lp1 statusCode:@200 json:@{
        @"C": @"1",
        @"T": @YES,
        @"M":@[ @{
            @"H":@"hubname",
            @"M":@"message",
            @"A":@"12345"
        } ]
    }];
    [SRMockLPTransport abortForTransport:lp1 statusCode:@200 json:@{}];
    [[SRMockLPTransport reconnectTransport:lp1 statusCode:@200 json:@{}] afterEnd:^(NSError * _Nullable error) {
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        [strongConnection stop];
    }];
    
    __block NSInteger startCount = 0;
    __weak XCTestExpectation *started = [self expectationWithDescription:@"closed"];
    connection.started = ^{
        startCount++;
        if (startCount == 2) {
            [started fulfill];
        }
    };
    
    __weak XCTestExpectation *reconnecting = [self expectationWithDescription:@"reconnecting"];
    connection.reconnecting = ^(){
        [reconnecting fulfill];
    };
    
    __weak XCTestExpectation *reconnected = [self expectationWithDescription:@"reconnected"];
    connection.reconnected = ^(){
        [reconnected fulfill];
    };
    
    connection.error = ^(NSError* err){
        XCTFail(@"connection errored");
    };
    
    __weak XCTestExpectation *closed = [self expectationWithDescription:@"closed"];
    connection.closed = ^{
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        [closed fulfill];
        [UMKMockURLProtocol reset];
        SRLongPollingTransport* lp2 = [SRMockLPTransport transport];
        [SRMockLPTransport negotiateForTransport:lp2];
        [SRMockLPTransport connectTransport:lp2 statusCode:@200 json:@{}];
        [strongConnection start:lp2];
    };
    
    [connection start:lp1];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end

@implementation SRLongPollingTransportTests (Poll)

- (void)testPollingClosesWithErrorDuringPoll {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRLongPollingTransport* lp = [SRMockLPTransport transport];
    [SRMockLPTransport negotiateForTransport:lp];
    [SRMockLPTransport connectTransport:lp statusCode:@200 json:@{
        @"C": @"1",
        @"M":@[ @{
            @"H":@"hubname",
            @"M":@"message",
            @"A":@"12345"
        } ]
    }];
    [SRMockLPTransport pollTransport:lp statusCode:@400 error:[[NSError alloc] initWithDomain:@"EXPECTED" code:NSURLErrorUnknown userInfo:nil]];
    
    __weak XCTestExpectation *started = [self expectationWithDescription:@"started"];
    connection.started = ^{
        [started fulfill];
    };
    
    connection.reconnecting = ^(){
        XCTFail(@"connection reconnecting");
    };
    
    connection.reconnected = ^(){
        XCTFail(@"connection reconnected");
    };
    
    __weak XCTestExpectation *errored = [self expectationWithDescription:@"errored"];
    connection.error = ^(NSError *error){
        [errored fulfill];
    };
    
    connection.closed = ^{
        XCTFail(@"connection closed");
    };
    
    [connection start:lp];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testPollingClosesWithCancelledDuringPoll {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRLongPollingTransport* lp = [SRMockLPTransport transport];
    [SRMockLPTransport negotiateForTransport:lp];
    [SRMockLPTransport connectTransport:lp statusCode:@200 json:@{
        @"C": @"1",
        @"M":@[ @{
            @"H":@"hubname",
            @"M":@"message",
            @"A":@"12345"
        } ]
    }];
    [SRMockLPTransport pollTransport:lp statusCode:@400 error:[[NSError alloc] initWithDomain:@"EXPECTED" code:NSURLErrorCancelled userInfo:nil]];
    
    __weak XCTestExpectation *started = [self expectationWithDescription:@"started"];
    connection.started = ^{
        [started fulfill];
    };
    
    connection.reconnecting = ^(){
        XCTFail(@"connection reconnnecting");
    };
    
    connection.reconnected = ^(){
        XCTFail(@"connection reconnected");
    };
    
    connection.error = ^(NSError *error){
        XCTFail(@"connection errored");
    };
    
    connection.closed = ^{
        XCTFail(@"connection closed");
    };
    
    [connection start:lp];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testConnectionStoppedBeforePollCompletes {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRLongPollingTransport* lp = [SRMockLPTransport transport];
    [SRMockLPTransport negotiateForTransport:lp];
    [SRMockLPTransport connectTransport:lp statusCode:@200 json:@{
        @"C": @"1",
        @"M":@[ @{
            @"H":@"hubname",
            @"M":@"message",
            @"A":@"12345"
        } ]
    }];
    __weak __typeof(&*connection)weakConnection = connection;
    [[SRMockLPTransport pollTransport:lp statusCode:@0 json:@{}] beforeData:^(NSData * _Nonnull data) {
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        [strongConnection stop];
    }];
    __weak XCTestExpectation *started = [self expectationWithDescription:@"started"];
    connection.started = ^{
        [started fulfill];
    };
    
    connection.reconnecting = ^(){
        XCTFail(@"connection reconnecting");
    };
    
    connection.reconnected = ^(){
        XCTFail(@"connection reconnected");
    };
    
    connection.error = ^(NSError *error){
        XCTFail(@"connection errored");
    };
    
    __weak XCTestExpectation *closed = [self expectationWithDescription:@"closed"];
    connection.closed = ^{
        [closed fulfill];
    };
    
    [connection start:lp];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testConnectionStoppedAfterPollCompletes {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRLongPollingTransport* lp = [SRMockLPTransport transport];
    [SRMockLPTransport negotiateForTransport:lp];
    [SRMockLPTransport connectTransport:lp statusCode:@200 json:@{
        @"C": @"1",
        @"M":@[ @{
            @"H":@"hubname",
            @"M":@"message",
            @"A":@"12345"
        } ]
    }];
    __weak __typeof(&*connection)weakConnection = connection;
    [[SRMockLPTransport pollTransport:lp statusCode:@200 json:@{
        @"C": @"2",
        @"M":@[ @{
            @"H":@"hubname",
            @"M":@"message",
            @"A":@"67890"
        } ]
    }] afterEnd:^(NSError * _Nullable error) {
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        [strongConnection stop];
    }];
    
    __weak XCTestExpectation *started = [self expectationWithDescription:@"started"];
    connection.started = ^{
        [started fulfill];
    };
    
    connection.reconnecting = ^(){
        XCTFail(@"connection reconnecting");
    };
    
    connection.reconnected = ^(){
        XCTFail(@"connection reconnected");
    };
    
    connection.error = ^(NSError *error){
        XCTFail(@"connection errored");
    };
    
    __weak XCTestExpectation *closed = [self expectationWithDescription:@"closed"];
    connection.closed = ^{
        [closed fulfill];
    };
    
    [connection start:lp];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testConnectionStoppedAndRestartedBeforePollCompletes {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRLongPollingTransport* lp1 = [SRMockLPTransport transport];
    [SRMockLPTransport negotiateForTransport:lp1];
    __weak __typeof(&*connection)weakConnection = connection;
    [SRMockLPTransport connectTransport:lp1 statusCode:@200 json:@{
        @"C": @"1",
        @"M":@[ @{
            @"H":@"hubname",
            @"M":@"message",
            @"A":@"12345"
        } ]
    }];
    [SRMockLPTransport abortForTransport:lp1 statusCode:@200 json:@{}];
    [[SRMockLPTransport pollTransport:lp1 statusCode:@0 json:@{}] beforeData:^(NSData * _Nonnull data) {
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        [strongConnection stop];
    }];
    
    __weak XCTestExpectation *started = [self expectationWithDescription:@"started"];
    connection.started = ^{
        [started fulfill];
    };
    
    connection.reconnecting = ^(){
        XCTFail(@"connection reconnecting");
    };
    
    connection.reconnected = ^(){
        XCTFail(@"connection reconnected");
    };
    
    connection.error = ^(NSError* err){
        XCTFail(@"connection errored");
    };
    
    __weak XCTestExpectation *closed = [self expectationWithDescription:@"closed"];
    connection.closed = ^{
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        [closed fulfill];
        [UMKMockURLProtocol reset];
        SRLongPollingTransport* lp2 = [SRMockLPTransport transport];
        [SRMockLPTransport negotiateForTransport:lp2];
        [SRMockLPTransport connectTransport:lp2 statusCode:@200 json:@{}];
        [strongConnection start:lp2];
    };
    
    [connection start:lp1];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testConnectionStoppedAndRestartedAfterPollCompletes {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRLongPollingTransport* lp1 = [SRMockLPTransport transport];
    [SRMockLPTransport negotiateForTransport:lp1];
    __weak __typeof(&*connection)weakConnection = connection;
    [SRMockLPTransport connectTransport:lp1 statusCode:@200 json:@{
        @"C": @"1",
        @"M":@[ @{
            @"H":@"hubname",
            @"M":@"message",
            @"A":@"12345"
        } ]
    }];
    [SRMockLPTransport abortForTransport:lp1 statusCode:@200 json:@{}];
    [[SRMockLPTransport pollTransport:lp1 statusCode:@200 json:@{}] afterEnd:^(NSError * _Nullable error) {
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        [strongConnection stop];
    }];
    
    __block NSInteger startCount = 0;
    __weak XCTestExpectation *started = [self expectationWithDescription:@"closed"];
    connection.started = ^{
        startCount++;
        if (startCount == 2) {
            [started fulfill];
        }
    };
    
    connection.reconnecting = ^(){
        XCTFail(@"connection reconnecting");
    };
    
    connection.reconnected = ^(){
        XCTFail(@"connection reconnected");
    };
    
    connection.error = ^(NSError* err){
        XCTFail(@"connection errored");
    };
    
    __weak XCTestExpectation *closed = [self expectationWithDescription:@"closed"];
    connection.closed = ^{
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        [closed fulfill];
        [UMKMockURLProtocol reset];
        SRLongPollingTransport* lp2 = [SRMockLPTransport transport];
        [SRMockLPTransport negotiateForTransport:lp2];
        [SRMockLPTransport connectTransport:lp2 statusCode:@200 json:@{}];
        [strongConnection start:lp2];
    };
    
    [connection start:lp1];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end

@implementation SRLongPollingTransportTests (Sending)

- (void)testTransportCanSendAndReceiveMessagesOnConnect {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRLongPollingTransport* lp = [SRMockLPTransport transport];
    [SRMockLPTransport negotiateForTransport:lp];
    [SRMockLPTransport connectTransport:lp statusCode:@200 json:@{
        @"C": @"1",
        @"M":@[ @{
            @"H":@"hubname",
            @"M":@"message1",
            @"A":@"12345"
        } ]
    }];
    [SRMockLPTransport pollTransport:lp statusCode:@200 json:@{
        @"C": @"2",
        @"M":@[ @{
            @"H":@"hubname",
            @"M":@"message2",
            @"A":@"12345"
        } ]
    }];
    [SRMockLPTransport sendForTransport:lp statusCode:@200 json:@{}];
    
    __weak XCTestExpectation *started = [self expectationWithDescription:@"started"];
    __weak __typeof(&*connection)weakConnection = connection;
    connection.started = ^(){
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        [strongConnection send:@"test" completionHandler:^(id response, NSError *error) {
            //after sending receive two more
        }];
        [started fulfill];
    };
    
    __weak XCTestExpectation *received = [self expectationWithDescription:@"received"];
    __block NSMutableArray* values = [[NSMutableArray alloc] init];
    connection.received = ^(id data) {
        [values addObject: data];
        if ([values count] == 3) {
            XCTAssertEqualObjects([[values objectAtIndex:0] valueForKey:@"M"], @"message1", @"did not receive message1");
            XCTAssertEqualObjects([[values objectAtIndex:2] valueForKey:@"M"], @"message2", @"did not receive message2");
            [received fulfill];
        }
    };
    
    connection.reconnecting = ^(){
        XCTFail(@"connection reconnecting");
    };
    
    connection.reconnected = ^(){
        XCTFail(@"connecting reconnected");
    };
    
    connection.error = ^(NSError *error) {
        XCTFail(@"connection errored");
    };
    
    connection.closed = ^() {
        XCTFail(@"connection closed");
    };
    
    [connection start:lp];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}


@end

@implementation SRLongPollingTransportTests (Abort)

@end

@implementation SRLongPollingTransportTests (LostConnection)

- (void)testLostConnectionCancelsEventStreamAndReconnects {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRLongPollingTransport* lp = [SRMockLPTransport transport];
    [SRMockLPTransport negotiateForTransport:lp];
    [[SRMockLPTransport connectTransport:lp statusCode:@200 json:@{
        @"C": @"1",
        @"M":@[ @{
            @"H":@"hubname",
            @"M":@"message",
            @"A":@"12345"
        } ]
   }] afterEnd:^(NSError * _Nullable error) {
        [lp lostConnection:connection];
    }];
    [SRMockLPTransport abortForTransport:lp statusCode:@200 json:@{}];
    [SRMockLPTransport reconnectTransport:lp statusCode:@200 json:@{
        @"C": @"2",
        @"M":@[ @{
            @"H":@"hubname",
            @"M":@"message",
            @"A":@"12345"
        } ]
    }];
    
    __weak XCTestExpectation *started = [self expectationWithDescription:@"started"];
    connection.started = ^(){
        [started fulfill];
    };
    
    __weak XCTestExpectation *reconnecting = [self expectationWithDescription:@"reconnecting"];
    connection.reconnecting = ^(){
        [reconnecting fulfill];
    };
    
    __weak XCTestExpectation *reconnected = [self expectationWithDescription:@"reconnected"];
    connection.reconnected = ^(){
        [reconnected fulfill];
    };
    
    connection.error = ^(NSError *error) {
        XCTFail(@"connection errored");
    };
    
    connection.closed = ^() {
        XCTFail(@"connection closed");
    };
    
    [connection start:lp];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end
