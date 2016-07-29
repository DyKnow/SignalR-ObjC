//
//  SRServerSentEventsTransportTests.m
//  SignalR.Client.ObjC
//
//  Created by Joel Dart on 8/2/15.
//  Copyright (c) 2015 DyKnow LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SRConnection.h"
#import "SRServerSentEventsTransport.h"
#import "SRMockClientTransport+SSE.h"
#import "SRMockClientTransport+OCMock.h"
#import "SRMockWaitBlockOperation.h"
#import "SRBlockOperation.h"
#import "SRMockSSEResponder.h"

@interface SRConnection (UnitTest)
@property (strong, nonatomic, readwrite) NSNumber * disconnectTimeout;
@end

@interface SRServerSentEventsTransportTests : XCTestCase

@end

@implementation SRServerSentEventsTransportTests

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
    SRServerSentEventsTransport* sse = [SRMockSSETransport transport];
    XCTAssert([[sse name] isEqualToString:@"serverSentEvents"]);
}

- (void)testSupportsKeepAlive {
    SRServerSentEventsTransport* sse = [SRMockSSETransport transport];
    XCTAssertTrue([sse supportsKeepAlive]);
}

@end

@implementation SRServerSentEventsTransportTests (MessageParsing)

- (void)testIgnoresInitializedAndEmptyLinesWhenParsingMessages {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRServerSentEventsTransport* sse = [SRMockSSETransport transport];
    [SRMockSSETransport negotiateForTransport:sse];
    SRMockSSEResponder *responder = [[SRMockSSEResponder alloc] initWithStatusCode:0 eventStream:@[
        [@"data: initialized\n\n" dataUsingEncoding:NSUTF8StringEncoding],
        [@"data: {\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}\n\n" dataUsingEncoding:NSUTF8StringEncoding]
    ]];
    [SRMockSSETransport connectTransport:sse responder:responder];
    
    __weak XCTestExpectation *received = [self expectationWithDescription:@"received"];
    connection.received = ^(NSDictionary * data){
        if ([[data valueForKey:@"M"] isEqualToString:@"message"]
            && [[data valueForKey:@"H"] isEqualToString:@"hubname"]
            && [[data valueForKey:@"A"] isEqualToString:@"12345"]) {
            [received fulfill];
        }
    };
    
    [connection start:sse];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testHandlesExtraEmptyLinesWhenParsingMessages {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRServerSentEventsTransport* sse = [SRMockSSETransport transport];
    [SRMockSSETransport negotiateForTransport:sse];
    SRMockSSEResponder *responder = [[SRMockSSEResponder alloc] initWithStatusCode:0 eventStream:@[
        [@"data: initialized\n\n\n" dataUsingEncoding:NSUTF8StringEncoding],
        [@"data: {\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}\n\n" dataUsingEncoding:NSUTF8StringEncoding]
    ]];
    [SRMockSSETransport connectTransport:sse responder:responder];
    
    __weak XCTestExpectation *received = [self expectationWithDescription:@"received"];
    connection.received = ^(NSString * data){
        if (data) {
            [received fulfill];
        }
    };
    
    [connection start:sse];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testHandlesNewLinesSpreadOutOverReads {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRServerSentEventsTransport* sse = [SRMockSSETransport transport];
    [SRMockSSETransport negotiateForTransport:sse];
    SRMockSSEResponder *responder = [[SRMockSSEResponder alloc] initWithStatusCode:0 eventStream:@[
        [@"data: initialized\n\n" dataUsingEncoding:NSUTF8StringEncoding],
        [@"data: {\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}" dataUsingEncoding:NSUTF8StringEncoding],
        [@"\n" dataUsingEncoding:NSUTF8StringEncoding]
    ]];
    [SRMockSSETransport connectTransport:sse responder:responder];
    
    __weak XCTestExpectation *received = [self expectationWithDescription:@"received"];
    connection.received = ^(NSString * data){
        if ([[data valueForKey:@"M"] isEqualToString:@"message"]
            && [[data valueForKey:@"H"] isEqualToString:@"hubname"]
            && [[data valueForKey:@"A"] isEqualToString:@"12345"]) {
            [received fulfill];
        }
    };
    
    [connection start:sse];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testConnectionDisconnectsWhenServerDisconnectReceived {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRServerSentEventsTransport* sse = [SRMockSSETransport transport];
    [SRMockSSETransport negotiateForTransport:sse];
    [SRMockSSETransport connectTransport:sse statusCode:@0 json:@{
        @"D": @YES
    }];
    
    __weak XCTestExpectation *closed = [self expectationWithDescription:@"closed"];
    connection.closed = ^(){
        [closed fulfill];
    };
    
    [connection start:sse];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)xtestConnectionReconnectsWhenServerReconnectReceived {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRServerSentEventsTransport* sse = [SRMockSSETransport transport];
    [SRMockSSETransport negotiateForTransport:sse];
    [SRMockSSETransport connectTransport:sse statusCode:@0 json:@{
        @"T": @YES
    }];
    
    [connection start:sse];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end

@implementation SRServerSentEventsTransportTests (Negotiate)

@end

@implementation SRServerSentEventsTransportTests (Initialize)

- (void)testEventStreamInitializesSuccessfully {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRServerSentEventsTransport* sse = [SRMockSSETransport transport];
    [SRMockSSETransport negotiateForTransport:sse];
    [SRMockSSETransport connectTransport:sse statusCode:@0 json:@{}];
    
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
    
    [connection start:sse];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testEventStreamClosesCleanlyBeforeInitializing {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRServerSentEventsTransport* sse = [SRMockSSETransport transport];
    [SRMockSSETransport negotiateForTransport:sse];
    [SRMockSSETransport connectTransport:sse responder:[[SRMockSSEResponder alloc] initWithStatusCode:200 eventStream:@[]]];
    [SRMockSSETransport abortForTransport:sse statusCode:@200 json:@{}];
    
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
        //This is an error of our own design
        XCTAssertEqual([error code], NSURLErrorZeroByteResource);
    };
    
    __weak XCTestExpectation *closed = [self expectationWithDescription:@"closed"];
    connection.closed = ^{
        [closed fulfill];
    };
    
    [connection start:sse];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testEventStreamClosesWithErrorBeforeInitializing {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRServerSentEventsTransport* sse = [SRMockSSETransport transport];
    [SRMockSSETransport negotiateForTransport:sse];
    [SRMockSSETransport connectTransport:sse statusCode:@400 error:[[NSError alloc] initWithDomain:@"EXPECTED" code:NSURLErrorUnknown userInfo:nil]];
    [SRMockSSETransport abortForTransport:sse statusCode:@200 json:@{}];
    
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
    
    __weak XCTestExpectation *closed = [self expectationWithDescription:@"closed"];
    connection.closed = ^{
        [closed fulfill];
    };
    
    [connection start:sse];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testEventStreamClosesWithCancelBeforeInitializing {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRServerSentEventsTransport* sse = [SRMockSSETransport transport];
    [SRMockSSETransport negotiateForTransport:sse];
    [SRMockSSETransport connectTransport:sse statusCode:@400 error:[[NSError alloc] initWithDomain:@"EXPECTED" code:NSURLErrorCancelled userInfo:nil]];
    [SRMockSSETransport abortForTransport:sse statusCode:@200 json:@{}];
    
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
    
    [connection start:sse];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testTransportCanTimeoutWhenItDoesNotReceiveInitializeMessage {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRServerSentEventsTransport* sse = [SRMockSSETransport transport];
    [SRMockSSETransport negotiateForTransport:sse];
    SRMockWaitBlockOperation* transportConnectTimeout = [[SRMockWaitBlockOperation alloc] initWithBlockOperationClass:[SRTransportConnectTimeoutBlockOperation class]];
    [[SRMockSSETransport connectTransport:sse statusCode:@0 json:@{}] beforeData:^(NSData * _Nonnull data) {
        NSString *eventStream = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if ([eventStream rangeOfString:@"initialized" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            transportConnectTimeout.afterWait();
        }
    }];
    [SRMockSSETransport abortForTransport:sse statusCode:@200 json:@{}];
    
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
    
    __weak XCTestExpectation *closed = [self expectationWithDescription:@"closed"];
    connection.closed = ^{
        [closed fulfill];
    };
    
    [connection start:sse];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testConnectionStoppedBeforeEventStreamInitializes {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRServerSentEventsTransport* sse = [SRMockSSETransport transport];
    [SRMockSSETransport negotiateForTransport:sse];
    __weak __typeof(&*connection)weakConnection = connection;
    [[SRMockSSETransport connectTransport:sse statusCode:@0 json:@{}] beforeData:^(NSData * _Nonnull data) {
         __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        NSString *eventStream = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if ([eventStream rangeOfString:@"initialized" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [strongConnection stop];
        }
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
    
    [connection start:sse];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testConnectionStoppedAfterEventStreamInitializes {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRServerSentEventsTransport* sse = [SRMockSSETransport transport];
    [SRMockSSETransport negotiateForTransport:sse];
    __weak __typeof(&*connection)weakConnection = connection;
    [[SRMockSSETransport connectTransport:sse statusCode:@0 json:@{}] afterData:^(NSData * _Nonnull data) {
         __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        NSString *eventStream = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if ([eventStream rangeOfString:@"initialized" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [strongConnection stop];
        }
    }];
    [SRMockSSETransport abortForTransport:sse statusCode:@200 json:@{}];
    
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
        XCTFail(@"connection errored");
    };
    
    __weak XCTestExpectation *closed = [self expectationWithDescription:@"closed"];
    connection.closed = ^{
        [closed fulfill];
    };
    
    [connection start:sse];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testConnectionStoppedAndRestartedBeforeEventStreamInitializes {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRServerSentEventsTransport* sse1 = [SRMockSSETransport transport];
    [SRMockSSETransport negotiateForTransport:sse1];
    __weak __typeof(&*connection)weakConnection = connection;
    [[SRMockSSETransport connectTransport:sse1 statusCode:@0 json:@{}] beforeData:^(NSData * _Nonnull data) {
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        NSString *eventStream = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if ([eventStream rangeOfString:@"initialized" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [strongConnection stop];
        }
    }];
    [SRMockSSETransport abortForTransport:sse1 statusCode:@200 json:@{}];
    
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
        SRServerSentEventsTransport* sse2 = [SRMockSSETransport transport];
        [SRMockSSETransport negotiateForTransport:sse2];
        [SRMockSSETransport connectTransport:sse2 statusCode:@0 json:@{}];
        [strongConnection start:sse2];
    };
    
    [connection start:sse1];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testConnectionStoppedAndRestartedAfterEventStreamInitializes {
    
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRServerSentEventsTransport* sse1 = [SRMockSSETransport transport];
    [SRMockSSETransport negotiateForTransport:sse1];
    __weak __typeof(&*connection)weakConnection = connection;
    [[SRMockSSETransport connectTransport:sse1 statusCode:@0 json:@{}] afterData:^(NSData * data){
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        NSString *eventStream = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if ([eventStream rangeOfString:@"initialized" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [strongConnection stop];
        }
    }];
    [SRMockSSETransport abortForTransport:sse1 statusCode:@200 json:@{}];
    
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
        SRServerSentEventsTransport* sse2 = [SRMockSSETransport transport];
        [SRMockSSETransport negotiateForTransport:sse2];
        [SRMockSSETransport connectTransport:sse2 statusCode:@0 json:@{}];
        [strongConnection start:sse2];
    };
    
    [connection start:sse1];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end

@implementation SRServerSentEventsTransportTests (Reconnect)

- (void)testEventStreamClosesCleanlyAfterInitializingShouldReconnect {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRServerSentEventsTransport* sse = [SRMockSSETransport transport];
    [SRMockSSETransport negotiateForTransport:sse];
    __block SRMockWaitBlockOperation* reconnectDelayBlock = nil;
    [[[SRMockSSETransport connectTransport:sse statusCode:@200 json:@{
        @"M":@[ @{
            @"H":@"hubname",
            @"M":@"message",
            @"A":@"12345"
        } ]
    }] beforeEnd:^(NSError * _Nullable error) {
        reconnectDelayBlock = [[SRMockWaitBlockOperation alloc] initWithBlockOperationClass:[SRServerSentEventsReconnectBlockOperation class]];
    }] afterEnd:^(NSError * _Nullable error) {
        reconnectDelayBlock.afterWait();
    }];
    [SRMockSSETransport abortForTransport:sse statusCode:@200 json:@{}];
    [SRMockSSETransport reconnectTransport:sse statusCode:@0 json:@{}];
    
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
    
    connection.error = ^(NSError* err){
        XCTFail(@"connection errored");
    };
    
    connection.closed = ^(){
        XCTFail(@"connection closed");
    };
    
    [connection start:sse];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testEventStreamClosesWithErrorAfterInitializingShouldReconnect {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRServerSentEventsTransport* sse = [SRMockSSETransport transport];
    [SRMockSSETransport negotiateForTransport:sse];
    __block SRMockWaitBlockOperation* reconnectDelayBlock = nil;
    [[[SRMockSSETransport connectTransport:sse statusCode:@500 json:@{
        @"M":@[ @{
            @"H":@"hubname",
            @"M":@"message",
            @"A":@"12345"
        } ]
    }] beforeEnd:^(NSError * _Nullable error) {
        reconnectDelayBlock = [[SRMockWaitBlockOperation alloc] initWithBlockOperationClass:[SRServerSentEventsReconnectBlockOperation class]];
    }] afterEnd:^(NSError * _Nullable error) {
        reconnectDelayBlock.afterWait();
    }];
    [SRMockSSETransport abortForTransport:sse statusCode:@200 json:@{}];
    [SRMockSSETransport reconnectTransport:sse statusCode:@0 json:@{}];
    
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
    
    __weak XCTestExpectation *errored = [self expectationWithDescription:@"errored"];
    connection.error = ^(NSError* err){
        [errored fulfill];
    };
    
    connection.closed = ^(){
        XCTFail(@"connection closed");
    };
    
    [connection start:sse];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

//TODO: should SSE really reconnect if the request is canceled?
- (void)testEventStreamClosesWithCancelAfterInitializingShouldReconnect {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRServerSentEventsTransport* sse = [SRMockSSETransport transport];
    [SRMockSSETransport negotiateForTransport:sse];
    __block SRMockWaitBlockOperation* reconnectDelayBlock = nil;
    [[[[SRMockSSETransport connectTransport:sse statusCode:@500 json:@{
        @"M":@[ @{
            @"H":@"hubname",
            @"M":@"message",
            @"A":@"12345"
        } ]
    }] failWithError:^NSError * _Nonnull{
        return [NSError errorWithDomain:@"UnitTesting" code:NSURLErrorCancelled userInfo:nil];
    }] beforeEnd:^(NSError * _Nullable error) {
        reconnectDelayBlock = [[SRMockWaitBlockOperation alloc] initWithBlockOperationClass:[SRServerSentEventsReconnectBlockOperation class]];
    }] afterEnd:^(NSError * _Nullable error) {
        reconnectDelayBlock.afterWait();
    }];
    [SRMockSSETransport abortForTransport:sse statusCode:@200 json:@{}];
    [SRMockSSETransport reconnectTransport:sse statusCode:@0 json:@{}];
    
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
    
    connection.error = ^(NSError* err){
        XCTFail(@"connection errored");
    };
    
    connection.closed = ^(){
        XCTFail(@"connection closed");
    };
    
    [connection start:sse];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}


- (void)testConnectionDisconnectsEventStreamAfterReconnectTimeout {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRServerSentEventsTransport* sse = [SRMockSSETransport transport];
    [SRMockSSETransport negotiateForTransport:sse];
     __block SRMockWaitBlockOperation* reconnectDelayBlock = nil;
    [[[SRMockSSETransport connectTransport:sse statusCode:@500 json:@{
        @"M":@[ @{
            @"H":@"hubname",
            @"M":@"message",
            @"A":@"12345"
        } ]
    }] beforeEnd:^(NSError * _Nullable error) {
        reconnectDelayBlock = [[SRMockWaitBlockOperation alloc] initWithBlockOperationClass:[SRServerSentEventsReconnectBlockOperation class]];
    }] afterEnd:^(NSError * _Nullable error) {
        reconnectDelayBlock.afterWait();
    }];
    
    __block SRMockWaitBlockOperation* reconnectTimeoutBlock = nil;
    connection.stateChanged = ^(connectionState state) {
        if (state == reconnecting) {
            reconnectTimeoutBlock = [[SRMockWaitBlockOperation alloc] initWithWaitTime:[connection.disconnectTimeout doubleValue]];
        }
    };
    [SRMockSSETransport abortForTransport:sse statusCode:@200 json:@{}];
    [[SRMockSSETransport reconnectTransport:sse statusCode:@0 json:@{}] beforeStart:^{
        reconnectTimeoutBlock.afterWait();
    }];
    
    __weak XCTestExpectation *started = [self expectationWithDescription:@"started"];
    connection.started = ^{
        [started fulfill];
    };
    
    __weak XCTestExpectation *reconnecting = [self expectationWithDescription:@"Retrying callback called"];
    connection.reconnecting = ^(){
        [reconnecting fulfill];
    };
    
    connection.reconnected = ^(){
        XCTFail(@"connecting reconnecting");
    };
    
    __weak XCTestExpectation *errored = [self expectationWithDescription:@"errored"];
    connection.error = ^(NSError* err){
        [errored fulfill];
    };
    
    __weak XCTestExpectation *closed = [self expectationWithDescription:@"closed"];
    connection.closed = ^(){
        [closed fulfill];
    };
    
    [connection start:sse];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testConnectionStoppedBeforeReconnectInitializes {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRServerSentEventsTransport* sse = [SRMockSSETransport transport];
    [SRMockSSETransport negotiateForTransport:sse];
    __block SRMockWaitBlockOperation* reconnectDelayBlock = nil;
    [[[SRMockSSETransport connectTransport:sse statusCode:@500 json:@{
        @"M":@[ @{
            @"H":@"hubname",
            @"M":@"message",
            @"A":@"12345"
        } ]
    }] beforeEnd:^(NSError * _Nullable error) {
        reconnectDelayBlock = [[SRMockWaitBlockOperation alloc] initWithBlockOperationClass:[SRServerSentEventsReconnectBlockOperation class]];
    }] afterEnd:^(NSError * _Nullable error) {
        reconnectDelayBlock.afterWait();
    }];
    [SRMockSSETransport abortForTransport:sse statusCode:@200 json:@{}];
    __weak __typeof(&*connection)weakConnection = connection;
    [[SRMockSSETransport reconnectTransport:sse statusCode:@0 json:@{}] beforeData:^(NSData * data){
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        NSString *eventStream = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if ([eventStream rangeOfString:@"initialized" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [strongConnection stop];
        }
    }];
    
    __weak XCTestExpectation *started = [self expectationWithDescription:@"started"];
    connection.started = ^(){
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
    connection.error = ^(NSError* err){
        [errored fulfill];
    };
    
    __weak XCTestExpectation *closed = [self expectationWithDescription:@"closed"];
    connection.closed = ^{
        [closed fulfill];
    };
    
    [connection start:sse];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testConnectionStoppedAfterReconnectInitializes {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRServerSentEventsTransport* sse = [SRMockSSETransport transport];
    [SRMockSSETransport negotiateForTransport:sse];
    __block SRMockWaitBlockOperation* reconnectDelayBlock = nil;
    [[[SRMockSSETransport connectTransport:sse statusCode:@500 json:@{
        @"M":@[ @{
            @"H":@"hubname",
            @"M":@"message",
            @"A":@"12345"
        } ]
    }] beforeEnd:^(NSError * _Nullable error) {
        reconnectDelayBlock = [[SRMockWaitBlockOperation alloc] initWithBlockOperationClass:[SRServerSentEventsReconnectBlockOperation class]];
    }] afterEnd:^(NSError * _Nullable error) {
        reconnectDelayBlock.afterWait();
    }];
    [SRMockSSETransport abortForTransport:sse statusCode:@200 json:@{}];
    __weak __typeof(&*connection)weakConnection = connection;
    [[SRMockSSETransport reconnectTransport:sse statusCode:@0 json:@{}] afterData:^(NSData * data){
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        NSString *eventStream = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if ([eventStream rangeOfString:@"initialized" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [strongConnection stop];
        }
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
    
    __weak XCTestExpectation *errored = [self expectationWithDescription:@"errored"];
    connection.error = ^(NSError* err){
        [errored fulfill];
    };
    
    __weak XCTestExpectation *closed = [self expectationWithDescription:@"closed"];
    connection.closed = ^{
        [closed fulfill];
    };
    
    [connection start:sse];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testConnectionStoppedAndRestartedBeforeReconnectInitializes {
    __block BOOL firstClosedCalled = NO;
    
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRServerSentEventsTransport* sse1 = [SRMockSSETransport transport];
    [SRMockSSETransport negotiateForTransport:sse1];
    __block SRMockWaitBlockOperation* reconnectDelayBlock = nil;
    [[[SRMockSSETransport connectTransport:sse1 statusCode:@500 json:@{
        @"M":@[ @{
            @"H":@"hubname",
            @"M":@"message",
            @"A":@"12345"
        } ]
    }] beforeEnd:^(NSError * _Nullable error) {
        reconnectDelayBlock = [[SRMockWaitBlockOperation alloc] initWithBlockOperationClass:[SRServerSentEventsReconnectBlockOperation class]];
    }] afterEnd:^(NSError * _Nullable error) {
        reconnectDelayBlock.afterWait();
    }];
    [SRMockSSETransport abortForTransport:sse1 statusCode:@200 json:@{}];
    __weak __typeof(&*connection)weakConnection = connection;
    [[SRMockSSETransport reconnectTransport:sse1 statusCode:@0 json:@{}] beforeData:^(NSData * data){
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        NSString *eventStream = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if ([eventStream rangeOfString:@"initialized" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [strongConnection stop];
        }
    }];
    
    __weak XCTestExpectation *reconnecting = [self expectationWithDescription:@"reconnecting"];
    connection.reconnecting = ^(){
        [reconnecting fulfill];
    };
    
    connection.reconnected = ^(){
        XCTFail(@"connection reconnected");
    };
    
    __weak XCTestExpectation *errored = [self expectationWithDescription:@"errored"];
    connection.error = ^(NSError* err){
        [errored fulfill];
    };
    
    //TODO: closed should really only be called once
    //__weak XCTestExpectation *closed = [self expectationWithDescription:@"closed"];
    connection.closed = ^{
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        //[closed fulfill];
        if (!firstClosedCalled) {
            [UMKMockURLProtocol reset];
            SRServerSentEventsTransport* sse2 = [SRMockSSETransport transport];
            [SRMockSSETransport negotiateForTransport:sse2];
            [SRMockSSETransport connectTransport:sse2 statusCode:@0 json:@{}];
            [strongConnection start:sse2];
        }
        firstClosedCalled = YES;
    };
    
    [connection start:sse1];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testConnectionStoppedAndRestartedAfterReconnectInitializes {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRServerSentEventsTransport* sse1 = [SRMockSSETransport transport];
    [SRMockSSETransport negotiateForTransport:sse1];
    __block SRMockWaitBlockOperation* reconnectDelayBlock = nil;
    [[[SRMockSSETransport connectTransport:sse1 statusCode:@500 json:@{
        @"M":@[ @{
            @"H":@"hubname",
            @"M":@"message",
            @"A":@"12345"
        } ]
    }] beforeEnd:^(NSError * _Nullable error) {
        reconnectDelayBlock = [[SRMockWaitBlockOperation alloc] initWithBlockOperationClass:[SRServerSentEventsReconnectBlockOperation class]];
    }] afterEnd:^(NSError * _Nullable error) {
        reconnectDelayBlock.afterWait();
    }];
    [SRMockSSETransport abortForTransport:sse1 statusCode:@200 json:@{}];
    __weak __typeof(&*connection)weakConnection = connection;
    [[SRMockSSETransport reconnectTransport:sse1 statusCode:@0 json:@{}] afterData:^(NSData * data){
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        NSString *eventStream = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if ([eventStream rangeOfString:@"initialized" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [strongConnection stop];
        }
    }];
    
    __weak XCTestExpectation *reconnecting = [self expectationWithDescription:@"reconnecting"];
    connection.reconnecting = ^(){
        [reconnecting fulfill];
    };
    
    __weak XCTestExpectation *reconnected = [self expectationWithDescription:@"reconnected"];
    connection.reconnected = ^(){
        [reconnected fulfill];
    };
    
    __weak XCTestExpectation *errored = [self expectationWithDescription:@"errored"];
    connection.error = ^(NSError* err){
        [errored fulfill];
    };
    
    __weak XCTestExpectation *closed = [self expectationWithDescription:@"closed"];
    connection.closed = ^{
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        [closed fulfill];
        [UMKMockURLProtocol reset];
        SRServerSentEventsTransport* sse2 = [SRMockSSETransport transport];
        [SRMockSSETransport negotiateForTransport:sse2];
        [SRMockSSETransport connectTransport:sse2 statusCode:@0 json:@{}];
        [strongConnection start:sse2];
    };
    
    [connection start:sse1];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end

@implementation SRServerSentEventsTransportTests (Sending)

- (void)testTransportCanSendAndReceiveMessagesOnConnect {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRServerSentEventsTransport* sse = [SRMockSSETransport transport];
    [SRMockSSETransport negotiateForTransport:sse];
    
    SRMockSSEResponder *responder = [[SRMockSSEResponder alloc] initWithStatusCode:0 eventStream:@[
        [@"data: initialized\n\n" dataUsingEncoding:NSUTF8StringEncoding],
        [@"data: {\"M\":[{\"H\":\"hubname\", \"M\":\"message1\", \"A\": \"12345\"}]}\n\n" dataUsingEncoding:NSUTF8StringEncoding],
        [@"data: {\"M\":[{\"H\":\"hubname\", \"M\":\"message2\", \"A\": \"12345\"}]}\n\n" dataUsingEncoding:NSUTF8StringEncoding]
    ]];
    [SRMockSSETransport connectTransport:sse responder:responder];
    [SRMockSSETransport sendForTransport:sse statusCode:@200 json:@{}];
    
    __weak XCTestExpectation *started = [self expectationWithDescription:@"started"];
    __weak __typeof(&*connection)weakConnection = connection;
    connection.started = ^(){
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        [strongConnection send:@"test" completionHandler:^(id response, NSError *error) {
            //after sending receive two more
            [responder eventStream:@[
                [@"data: {\"M\":[{\"H\":\"hubname\", \"M\":\"message3\", \"A\": \"12345\"}]}\n\n" dataUsingEncoding:NSUTF8StringEncoding],
                [@"data: {\"M\":[{\"H\":\"hubname\", \"M\":\"message4\", \"A\": \"12345\"}]}\n\n" dataUsingEncoding:NSUTF8StringEncoding]
            ]];
        }];
        [started fulfill];
    };
    
    __weak XCTestExpectation *received = [self expectationWithDescription:@"received"];
    __block NSMutableArray* values = [[NSMutableArray alloc] init];
    connection.received = ^(id data) {
        [values addObject: data];
        if ([values count] == 5) {
            XCTAssertEqualObjects([[values objectAtIndex:0] valueForKey:@"M"], @"message1", @"did not receive message1");
            XCTAssertEqualObjects([[values objectAtIndex:1] valueForKey:@"M"], @"message2", @"did not receive message2");
            XCTAssertEqualObjects([[values objectAtIndex:3] valueForKey:@"M"], @"message3", @"did not receive message3");
            XCTAssertEqualObjects([[values objectAtIndex:4] valueForKey:@"M"], @"message4", @"did not receive message4");
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
    
    [connection start:sse];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end

@implementation SRServerSentEventsTransportTests (Abort)

@end

@implementation SRServerSentEventsTransportTests (LostConnection)

- (void)testLostConnectionCancelsEventStreamAndReconnects {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRServerSentEventsTransport* sse = [SRMockSSETransport transport];
    [SRMockSSETransport negotiateForTransport:sse];
    __block SRMockWaitBlockOperation* reconnectDelayBlock = nil;
    [[SRMockSSETransport connectTransport:sse statusCode:@0 json:@{
       @"M":@[ @{
           @"H":@"hubname",
           @"M":@"message",
           @"A":@"12345"
       } ]
    }] afterData:^(NSData * _Nonnull data) {
        NSString *eventStream = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if ([eventStream rangeOfString:@"12345" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            reconnectDelayBlock = [[SRMockWaitBlockOperation alloc] initWithBlockOperationClass:[SRServerSentEventsReconnectBlockOperation class]];
            [sse lostConnection:connection];
            //TODO: Hack to allow NSURLProtocolClient to finish pumping messages
            [NSThread sleepForTimeInterval:.1];
            reconnectDelayBlock.afterWait();
        }
    }];
    [SRMockSSETransport abortForTransport:sse statusCode:@200 json:@{}];
    [SRMockSSETransport reconnectTransport:sse statusCode:@0 json:@{}];
    
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
    
    [connection start:sse];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end

@implementation SRServerSentEventsTransportTests (Ping)

- (void)xtestPingIntervalStopsTheConnectionOn401s {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRServerSentEventsTransport* sse = [SRMockSSETransport transport];
    [SRMockSSETransport negotiateForTransport:sse];
    [SRMockSSETransport connectTransport:sse statusCode:@0 json:@{
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
    
    connection.reconnecting = ^(){
         XCTFail(@"connection reconnecting");
    };
    
    connection.reconnected = ^(){
        XCTFail(@"connection reconencted");
    };
    
    __weak XCTestExpectation *errored = [self expectationWithDescription:@"errored"];
    connection.error = ^(NSError *error){
        [errored fulfill];
        XCTAssert(NO, @"todo: verify it's a 401");
    };
    
    connection.closed = ^() {
        XCTFail(@"connection closed");
    };
    
    [connection start:sse];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)xtestPingIntervalStopsTheConnectionOn403s {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRServerSentEventsTransport* sse = [SRMockSSETransport transport];
    [SRMockSSETransport negotiateForTransport:sse];
    [SRMockSSETransport connectTransport:sse statusCode:@0 json:@{
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
    
    connection.reconnecting = ^(){
        XCTFail(@"connection reconnecting");
    };
    
    connection.reconnected = ^(){
        XCTFail(@"connection reconencted");
    };
    
    __weak XCTestExpectation *errored = [self expectationWithDescription:@"errored"];
    connection.error = ^(NSError *error){
        [errored fulfill];
        XCTAssert(NO, @"todo: verify it's a 403");
    };
    
    connection.closed = ^() {
        XCTFail(@"connection closed");
    };
    
    [connection start:sse];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)xtestPingIntervalBehavesAppropriately {
    XCTAssert(NO, @"not implemented");
}

@end
