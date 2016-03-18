//
//  SRServerSentEventsTransportTests.m
//  SignalR.Client.ObjC
//
//  Created by Joel Dart on 8/2/15.
//  Copyright (c) 2015 DyKnow LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SRServerSentEventsTransport.h"
#import <AFNetworking/AFNetworking.h>
#import "SRConnection.h"
#import "SRConnectionDelegate.h"
#import "SRNegotiationResponse.h"
#import "SRMockNetwork.h"
#import "SRMockClientTransport.h"
#import "SRMockSSENetworkStream.h"
#import "SRMockWaitBlockOperation.h"

@interface SRConnection (UnitTest)
@property (strong, nonatomic, readwrite) NSNumber * disconnectTimeout;
@end

@interface SRServerSentEventsTransport ()
@property (strong, nonatomic, readwrite) NSOperationQueue *serverSentEventsOperationQueue;
@property (assign) BOOL stop;
@end

@interface SRServerSentEventsTransportTests : XCTestCase

@end

@implementation SRServerSentEventsTransportTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testStartCallsTheCompletionHandlerAfterSuccess {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Handler called"];
    
    SRMockSSENetworkStream *NetworkMock = [[SRMockSSENetworkStream alloc] init];
    
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    connection.connectionToken = @"10101010101";
    connection.connectionId = @"10101";
    [connection changeState:disconnected toState:connected];
    
    SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    sse.serverSentEventsOperationQueue = nil;//set to nil to get around weird ARC OCMock bugs http://stackoverflow.com/questions/18121902/using-ocmock-on-nsoperation-gives-bad-access
    
    [NetworkMock prepareForOpeningResponse:^{
        [sse start: connection connectionData:@"12345" completionHandler:^(id response, NSError *error){
            [expectation fulfill];
        }];
    }];
        
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testParsesInitialBuffer {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Handler called"];
    
    SRMockSSENetworkStream *NetworkMock = [[SRMockSSENetworkStream alloc] init];
    
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    connection.connectionToken = @"10101010101";
    connection.connectionId = @"10101";
    [connection changeState:disconnected toState:connected];
    
    SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    sse.serverSentEventsOperationQueue = nil;//set to nil to get around weird ARC OCMock bugs http://stackoverflow.com/questions/18121902/using-ocmock-on-nsoperation-gives-bad-access
    
    [NetworkMock prepareForOpeningResponse:@"data: {}\n" then:^{
        [sse start: connection connectionData:@"12345" completionHandler:^(id response, NSError *error){
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testIgnoresInitializedAndEmptyLinesWhenParsingMessages {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Handler called"];
    
    SRMockSSENetworkStream *NetworkMock = [[SRMockSSENetworkStream alloc] init];
    
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    connection.connectionToken = @"10101010101";
    connection.connectionId = @"10101";
    [connection changeState:disconnected toState:connected];
    
    connection.received = ^(NSDictionary * data){
        if ([[data valueForKey:@"M"] isEqualToString:@"message"]
            && [[data valueForKey:@"H"] isEqualToString:@"hubname"]
            && [[data valueForKey:@"A"] isEqualToString:@"12345"]) {
            [expectation fulfill];
        }
    };
    
    SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    sse.serverSentEventsOperationQueue = nil;//set to nil to get around weird ARC OCMock bugs http://stackoverflow.com/questions/18121902/using-ocmock-on-nsoperation-gives-bad-access
    
    [NetworkMock prepareForOpeningResponse:@"data: initialized\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}\n\n" then:^{
        [sse start: connection connectionData:@"12345" completionHandler:^(id response, NSError *error){}];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testConnectionInitialFailureUsesCallback {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Handler called"];
    
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    connection.connectionToken = @"10101010101";
    connection.connectionId = @"10101";
    [connection changeState:disconnected toState:connected];
    
    SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    sse.serverSentEventsOperationQueue = nil;//set to nil to get around weird ARC OCMock bugs http://stackoverflow.com/questions/18121902/using-ocmock-on-nsoperation-gives-bad-access
    
    [SRMockNetwork mockHttpRequestOperationForClass:[AFHTTPRequestOperation class]
                                         statusCode:@400
                                              error:[[NSError alloc] initWithDomain:@"EXPECTED" code:42 userInfo:nil]];

    [sse start: connection connectionData:@"12345" completionHandler:^(id response, NSError *error){
        if(error) {
            [expectation fulfill];
        }
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testConnectionErrorRetries__RetriesAfterADelay__CommunicatesLifeCycleViaConnection {
    XCTestExpectation *initialized = [self expectationWithDescription:@"initialized"];
    SRMockSSENetworkStream *NetworkMock = [[SRMockSSENetworkStream alloc] init];
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    connection.connectionToken = @"10101010101";
    connection.connectionId = @"10101";
    connection.disconnectTimeout = @30;
    connection.transportConnectTimeout =@10;
    [connection changeState:disconnected toState:connected];
 
    SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    sse.serverSentEventsOperationQueue = nil;//set to nil to get around weird ARC OCMock bugs http://stackoverflow.com/questions/18121902/using-ocmock-on-nsoperation-gives-bad-access
    
    [NetworkMock prepareForOpeningResponse:@"data: initialized\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}\n\n" then:^{
        [sse start: connection connectionData:@"12345" completionHandler:^(id response, NSError *error){
            [initialized fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
    
    XCTestExpectation *reconnecting = [self expectationWithDescription:@"Retrying callback called"];
    connection.reconnecting = ^(){
        [reconnecting fulfill];
    };
    
    XCTestExpectation *reconnected = [self expectationWithDescription:@"Retry callback called"];
    connection.reconnected = ^(){
        [reconnected fulfill];
    };
    
    SRMockWaitBlockOperation* reconnectDelay = [[SRMockWaitBlockOperation alloc] initWithWaitTime:[[sse reconnectDelay] doubleValue]];
    [NetworkMock prepareForError:[[NSError alloc]initWithDomain:@"EXPECTED" code:42 userInfo:nil]];
    [NetworkMock stopMocking];
    SRMockSSENetworkStream* NetworkReconnectMock = [[SRMockSSENetworkStream alloc]init];
    [reconnectDelay.mock stopMocking];//dont want to accidentally get other blocks
    [NetworkReconnectMock prepareForOpeningResponse:^{
        reconnectDelay.afterWait();
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error){
            NSLog(@"Sub-Timeout Error: %@", error);
        }
    }];
}

- (void)testLostConnectionAbortsAllConnectionsAndReconnects {
    // happens when healthy connection misses too many heartbeats
    XCTestExpectation *initialized = [self expectationWithDescription:@"initialized"];
    SRMockSSENetworkStream* NetworkMock = [[SRMockSSENetworkStream alloc] init];
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    connection.connectionToken = @"10101010101";
    connection.connectionId = @"10101";
    connection.disconnectTimeout = @30;
    connection.transportConnectTimeout =@10;
    [connection changeState:disconnected toState:connected];
    
    SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    id queueMock = [OCMockObject niceMockForClass:[NSOperationQueue class]];
    [[queueMock expect] cancelAllOperations];
    sse.serverSentEventsOperationQueue = queueMock;

    [NetworkMock prepareForOpeningResponse:@"data: initialized\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}\n\n" then:^{
        [sse start: connection connectionData:@"12345" completionHandler:^(id response, NSError *error){
            [initialized fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error); return;
        }
    }];
    
    XCTestExpectation *reconnecting = [self expectationWithDescription:@"Retrying callback called"];
    connection.reconnecting = ^(){
        [reconnecting fulfill];
    };
    
    XCTestExpectation *reconnected = [self expectationWithDescription:@"Retry callback called"];
    connection.reconnected = ^(){
        [reconnected fulfill];
    };

    //loses connection immediately, everything gets cleared out, but we
    //do not reconnect till later
    [sse lostConnection:connection];
    [queueMock verify];//clears out the queue after the timeout
    
    SRMockWaitBlockOperation* reconnectDelay = [[SRMockWaitBlockOperation alloc] initWithWaitTime:[[sse reconnectDelay] doubleValue]];
    NSError *cancelledError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];//when the operation is cancelled, it yields the NSURLErrorCancelled error. From https://github.com/AFNetworking/AFNetworking/blob/c9bbbeb9cae6aeceef5353fd273fc48329009c3f/AFNetworking/AFURLConnectionOperation.m#L502
    [NetworkMock prepareForError:cancelledError];
    [NetworkMock stopMocking];
    SRMockSSENetworkStream* NetworkReconnectMock = [[SRMockSSENetworkStream alloc]init];
    [reconnectDelay.mock stopMocking];//dont want to accidentally get other blocks
    [NetworkReconnectMock prepareForOpeningResponse:^{
        reconnectDelay.afterWait();
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error); return;
        }
    }];
}

- (void)testDisconnectsOnReconnectTimeout {
    XCTestExpectation *initialized = [self expectationWithDescription:@"initialized"];
    SRMockSSENetworkStream* NetworkMock = [[SRMockSSENetworkStream alloc] init];
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    connection.connectionToken =
    connection.connectionId = @"10101";
    connection.disconnectTimeout = @30;
    connection.transportConnectTimeout =@10;
    
    __block SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    sse.serverSentEventsOperationQueue = nil;//set to nil to avoid ARC error http://stackoverflow.com/questions/18121902/using-ocmock-on-nsoperation-gives-bad-access
    
    id json = @{
        @"ConnectionId": @"10101",
        @"ConnectionToken": @"10101010101",
        @"DisconnectTimeout": @30,
        @"ProtocolVersion": @"1.3.0.0",
        @"TransportConnectTimeout": @10
    };
    [SRMockClientTransport negotiateForTransport:sse statusCode:@200 json:json];
    
    connection.started = ^{
        [initialized fulfill];
    };
    
    [NetworkMock prepareForOpeningResponse:@"data: initialized\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}\n\n" then:^{
        [connection start:sse];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error); return;
        }
    }];
    
    XCTestExpectation *reconnecting = [self expectationWithDescription:@"Retrying callback called"];
    connection.reconnecting = ^(){
        [reconnecting fulfill];
    };
    
    connection.reconnected = ^(){
        XCTAssert(NO, @"unexpected change!");
    };
    
    XCTestExpectation *closed = [self expectationWithDescription:@"closed"];
    connection.closed = ^(){
        [closed fulfill];
    };
    
    SRMockWaitBlockOperation* reconnectDelay = [[SRMockWaitBlockOperation alloc] initWithWaitTime:[[sse reconnectDelay] doubleValue]];
    NSError *cancelledError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
    [NetworkMock prepareForError:cancelledError];
    [NetworkMock stopMocking];
    [reconnectDelay.mock stopMocking];//dont want to accidentally get other blocks
    SRMockWaitBlockOperation* reconnectTimeoutBlock = [[SRMockWaitBlockOperation alloc] initWithWaitTime:[connection.disconnectTimeout doubleValue]];
    reconnectDelay.afterWait();
    
    //lets track that we clear out the queue when we timeout
    id queueMock = [OCMockObject niceMockForClass:[NSOperationQueue class]];
    [[queueMock expect] cancelAllOperations];
    sse.serverSentEventsOperationQueue = queueMock;
    
    //connection timed out without succeeding
    reconnectTimeoutBlock.afterWait();
    
    [queueMock verify];
    XCTAssertTrue([sse stop], @"did not stop the transport. this makes the transport unpredictable");
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error){
            NSLog(@"Sub-Timeout Error: %@", error);
        }
        sse = nil;
    }];
}

- (void)xtestHandlesDisconnectMessageFromConnection {
    XCTAssert(NO, @"not implemented - need to determine support. 2.0.2 sends the D:1 disconenct message but latest does not");
}

- (void)testHandlesExtraEmptyLinesWhenParsingMessages {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Handler called"];
    
    SRMockSSENetworkStream * NetworkMock = [[SRMockSSENetworkStream alloc] init];
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    connection.connectionToken = @"10101010101";
    connection.connectionId = @"10101";
    [connection changeState:disconnected toState:connected];

    connection.received = ^(NSString * data){
        if (data) {
            [expectation fulfill];
        }
    };
    
    SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    sse.serverSentEventsOperationQueue = nil;//set to nil to get around weird ARC OCMock bugs http://stackoverflow.com/questions/18121902/using-ocmock-on-nsoperation-gives-bad-access
    
    [NetworkMock prepareForOpeningResponse:@"data: initialized\n\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}\n\n" then:^{
        [sse start: connection connectionData:@"12345" completionHandler:^(id response, NSError *error){}];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testHandlesNewLinesSpreadOutOverReads {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Handler called"];
    
    SRMockSSENetworkStream * NetworkMock = [[SRMockSSENetworkStream alloc] init];
    SRConnection* connection = [[SRConnection alloc]initWithURLString:@"http://localhost:0000"];
    connection.connectionToken = @"10101010101";
    connection.connectionId = @"10101";
    [connection changeState:disconnected toState:connected];
    
    connection.received = ^(NSDictionary * data){
        if ([[data valueForKey:@"M"] isEqualToString:@"message"]
            && [[data valueForKey:@"H"] isEqualToString:@"hubname"]
            && [[data valueForKey:@"A"] isEqualToString:@"12345"]) {
            [expectation fulfill];
        }
    };

    SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    sse.serverSentEventsOperationQueue = nil;//set to nil to get around weird ARC OCMock bugs http://stackoverflow.com/questions/18121902/using-ocmock-on-nsoperation-gives-bad-access
    
    [NetworkMock prepareForOpeningResponse:@"data: initialized\n\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}" then:^{
        [sse start: connection connectionData:@"12345" completionHandler:^(id response, NSError *error){}];
    }];
    
    [NetworkMock prepareForNextResponse:@"\n" then:nil];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testTransportCanTimeoutWhenItDoesNotReceiveInitializeMessage {
    XCTestExpectation *initialized = [self expectationWithDescription:@"initialized"];
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    
    SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    sse.serverSentEventsOperationQueue = nil;//set to nil to avoid ARC error http://stackoverflow.com/questions/18121902/using-ocmock-on-nsoperation-gives-bad-access
    
    id json = @{
        @"ConnectionId": @"10101",
        @"ConnectionToken": @"10101010101",
        @"DisconnectTimeout": @30,
        @"ProtocolVersion": @"1.3.0.0",
        @"TransportConnectTimeout": @10
    };
    [SRMockClientTransport negotiateForTransport:sse statusCode:@200 json:json];
    
    connection.started = ^{
        XCTAssert(NO, @"Connection started");
    };
    
    connection.error = ^(NSError *error){
        [initialized fulfill];
    };
    
    SRMockWaitBlockOperation* transportConnectTimeout = [[SRMockWaitBlockOperation alloc] initWithWaitTime: 10];
    [connection start:sse];
    
    [transportConnectTimeout.mock stopMocking];
    transportConnectTimeout.afterWait();
    
    XCTAssertEqual([connection.transportConnectTimeout doubleValue], transportConnectTimeout.waitTime, @"not implemented");

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testStart_Stop_StartTriggersTheCorrectCallbacks {
    XCTestExpectation *initialized = [self expectationWithDescription:@"initialized"];
    SRMockSSENetworkStream* NetworkMock = [[SRMockSSENetworkStream alloc] init];
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    connection.transportConnectTimeout =@10;
    
    SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    sse.serverSentEventsOperationQueue = nil;//set to nil to avoid ARC error http://stackoverflow.com/questions/18121902/using-ocmock-on-nsoperation-gives-bad-access
    
    id json = @{
        @"ConnectionId": @"10101",
        @"ConnectionToken": @"10101010101",
        @"DisconnectTimeout": @30,
        @"ProtocolVersion": @"1.3.0.0",
        @"TransportConnectTimeout": @10
    };
    [SRMockClientTransport negotiateForTransport:sse statusCode:@200 json:json];
    
    __block BOOL firstClosedCalled = NO;
    __block int startCount = 0;
    
    connection.started = ^{
        startCount++;
        [initialized fulfill];
        XCTAssertTrue(firstClosedCalled, @"only get started after the error fails first");
    };
    
    connection.closed = ^{
        firstClosedCalled = YES;
    };
    
    connection.error = ^(NSError *error){
        XCTAssert(NO, @"errors might be expected in the promise but not for the callbacks");
    };
    
    [connection start:sse];
    [connection stop];
    
    [NetworkMock prepareForOpeningResponse:@"data: initialized\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}\n\n" then:^{
        [connection start:sse];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
        XCTAssert(startCount == 1, @"expected exactly one started callback");
    }];
}

- (void)xtestPingIntervalStopsTheConnectionOn401s {
    XCTestExpectation *initialized = [self expectationWithDescription:@"initialized"];
    SRMockSSENetworkStream* NetConnect = [[SRMockSSENetworkStream alloc] init];
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    
    SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    sse.serverSentEventsOperationQueue = nil;//set to nil to avoid ARC error http://stackoverflow.com/questions/18121902/using-ocmock-on-nsoperation-gives-bad-access
    
    id json = @{
        @"ConnectionId": @"10101",
        @"ConnectionToken": @"10101010101",
        @"DisconnectTimeout": @30,
        @"ProtocolVersion": @"1.3.0.0",
        @"TransportConnectTimeout": @10
    };
    [SRMockClientTransport negotiateForTransport:sse statusCode:@200 json:json];
    
    connection.error = ^(NSError *error){
        [initialized fulfill];
        XCTAssert(NO, @"todo: verify it's a 401");
    };
    
    
    [NetConnect prepareForOpeningResponse: @"data: initialized\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}\n\n" then:^{
        [connection start:sse];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)xtestPingIntervalStopsTheConnectionOn403s {
    XCTestExpectation *initialized = [self expectationWithDescription:@"initialized"];
    SRMockSSENetworkStream* NetConnect = [[SRMockSSENetworkStream alloc] init];
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    
    SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    sse.serverSentEventsOperationQueue = nil;//set to nil to avoid ARC error http://stackoverflow.com/questions/18121902/using-ocmock-on-nsoperation-gives-bad-access
    
    id json = @{
        @"ConnectionId": @"10101",
        @"ConnectionToken": @"10101010101",
        @"DisconnectTimeout": @30,
        @"ProtocolVersion": @"1.3.0.0",
        @"TransportConnectTimeout": @10
    };
    [SRMockClientTransport negotiateForTransport:sse statusCode:@200 json:json];
    
    connection.error = ^(NSError *error){
        [initialized fulfill];
        XCTAssert(NO, @"todo: verify it's a 403");
    };
    
    
    [NetConnect prepareForOpeningResponse:@"data: initialized\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}\n\n" then:^{
        [connection start:sse];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)xtestPingIntervalBehavesAppropriately {
    // This is an example of a functional test case.
    XCTAssert(NO, @"not implemented");
}

- (void)xtestConnectionDataFlowsWithAllRequestsToServer {
    // This is an example of a functional test case.
    XCTAssert(NO, @"not implemented");
}

- (void)testReconnectExceedingTheReconnectWindowResultsInTheConnectionDisconnect {
    XCTestExpectation *initialized = [self expectationWithDescription:@"initialized"];
    SRMockSSENetworkStream* NetworkMock = [[SRMockSSENetworkStream alloc] init];
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];

    SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    sse.serverSentEventsOperationQueue = nil;//set to nil to avoid ARC error http://stackoverflow.com/questions/18121902/using-ocmock-on-nsoperation-gives-bad-access
    
    id json = @{
        @"ConnectionId": @"10101",
        @"ConnectionToken": @"10101010101",
        @"DisconnectTimeout": @30,
        @"ProtocolVersion": @"1.3.0.0",
        @"TransportConnectTimeout": @10
    };
    [SRMockClientTransport negotiateForTransport:sse statusCode:@200 json:json];
    
    connection.started = ^{
        [initialized fulfill];
    };
    
    [NetworkMock prepareForOpeningResponse:@"data: initialized\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}\n\n" then:^{
        [connection start:sse];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error); return;
        }
    }];
    
    XCTestExpectation *disconnected = [self expectationWithDescription:@"disconnected"];
    connection.reconnected = ^(){
        XCTAssert(NO, @"unexpected change!");
    };
    connection.closed = ^(){
        [disconnected fulfill];
    };
    
    SRMockWaitBlockOperation* reconnectDelay = [[SRMockWaitBlockOperation alloc] initWithWaitTime:[[sse reconnectDelay] doubleValue]];
    NSError *cancelledError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
    [NetworkMock prepareForError:cancelledError];
    [NetworkMock stopMocking];
    [reconnectDelay.mock stopMocking];//dont want to accidentally get other blocks
    SRMockWaitBlockOperation* reconnectTimeoutBlock = [[SRMockWaitBlockOperation alloc] initWithWaitTime:[connection.disconnectTimeout doubleValue]];
    //retry has waited now,
    reconnectDelay.afterWait();
    XCTAssertEqual([connection.disconnectTimeout doubleValue], reconnectTimeoutBlock.waitTime, @"got timeout value from an unexpected place - check to be sure we are pulling from the connection");

    //connection timed out without succeeding
    reconnectTimeoutBlock.afterWait();
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error){
            NSLog(@"Sub-Timeout Error: %@", error);
        }
    }];
}

- (void)testConnectionCanBeStoppedDuringTransportStart {
    XCTestExpectation *initialized = [self expectationWithDescription:@"initialized"];
    SRMockSSENetworkStream* NetworkMock = [[SRMockSSENetworkStream alloc] init];
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    
    SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    sse.serverSentEventsOperationQueue = nil;//set to nil to avoid ARC error http://stackoverflow.com/questions/18121902/using-ocmock-on-nsoperation-gives-bad-access
    
    id json = @{
        @"ConnectionId": @"10101",
        @"ConnectionToken": @"10101010101",
        @"DisconnectTimeout": @30,
        @"ProtocolVersion": @"1.3.0.0",
        @"TransportConnectTimeout": @10
    };
    [SRMockClientTransport negotiateForTransport:sse statusCode:@200 json:json];
    
    connection.closed = ^{
        [initialized fulfill];
    };
    
    connection.error = ^(NSError* err){
        XCTAssert(NO, @"Error was triggered");
    };
    
    connection.started = ^(){
        XCTAssert(NO, @"start was triggered");
    };
    
    [NetworkMock prepareForOpeningResponse:^{
        [connection start:sse];
    }];
    [connection stop];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error); return;
        }
        XCTAssertEqual(connection.state, disconnected, @"Connection was not disconnected");
        XCTAssertEqual(connection.transport, nil, @"Transport was not cleared after stop");
    }];
}

- (void)testConnectionCanBeStoppedPriorToTransportStart {
    XCTestExpectation *initialized = [self expectationWithDescription:@"initialized"];
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    
    SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    sse.serverSentEventsOperationQueue = nil;//set to nil to avoid ARC error http://stackoverflow.com/questions/18121902/using-ocmock-on-nsoperation-gives-bad-access
    
    id pmock = [OCMockObject partialMockForObject: sse];
    [[[pmock stub] andDo:^(NSInvocation *invocation) {
        __unsafe_unretained void (^ callbackOut)(SRNegotiationResponse * response, NSError *error);
        [invocation getArgument: &callbackOut atIndex: 4];
        //do not respond to negotiate!!
        //we will stop the connection before its completion
    }] negotiate:[OCMArg any] connectionData:[OCMArg any] completionHandler:[OCMArg any]];
    
    connection.closed = ^{
        [initialized fulfill];
    };
    
    connection.error = ^(NSError* err){
        XCTAssert(NO, @"Error was triggered");
    };
    
    connection.started = ^(){
        XCTAssert(NO, @"start was triggered");
    };
    
    [connection start:sse];
    [connection stop];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error); return;
        }
        XCTAssertEqual(connection.state, disconnected, @"Connection was not disconnected");
        XCTAssertEqual(connection.transport, nil, @"Transport was not cleared after stop");
    }];
}

- (void)testTransportCanSendAndReceiveMessagesOnConnect {
    XCTestExpectation *initialized = [self expectationWithDescription:@"initialized"];
    SRMockSSENetworkStream* NetworkMock = [[SRMockSSENetworkStream alloc] init];
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    __weak __typeof(&*connection)weakConnection = connection;
    __weak __typeof(&*NetworkMock)weakNetworkMock = NetworkMock;
    
    __block SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    sse.serverSentEventsOperationQueue = nil;//set to nil to avoid ARC error
    
    id json = @{
        @"ConnectionId": @"10101",
        @"ConnectionToken": @"10101010101",
        @"DisconnectTimeout": @30,
        @"ProtocolVersion": @"1.3.0.0",
        @"TransportConnectTimeout": @10
    };
    id transportMock = [SRMockClientTransport negotiateForTransport:sse statusCode:@200 json:json];
    [SRMockClientTransport sendForMockTransport:transportMock statusCode:@200 json:nil];

    __block NSMutableArray* values = [[NSMutableArray alloc] init];
    
    connection.started = ^(){
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        [strongConnection send:@"test" completionHandler:^(id response, NSError *error) {
            //after sending receive two more
            __strong __typeof(&*weakNetworkMock)strongNetworkMock = weakNetworkMock;
            [strongNetworkMock prepareForNextResponse:@"data: {\"M\":[{\"H\":\"hubname\", \"M\":\"message3\", \"A\": \"12345\"}]}\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message4\", \"A\": \"12345\"}]}\n\n" then:nil];
        }];
    };
    
    connection.received = ^(id data) {
        [values addObject: data];
        if ([values count] == 4){

            XCTAssertEqualObjects([[values objectAtIndex:0] valueForKey:@"M"], @"message1", @"did not receive message1");
            XCTAssertEqualObjects([[values objectAtIndex:1] valueForKey:@"M"], @"message2", @"did not receive message2");
            XCTAssertEqualObjects([[values objectAtIndex:2] valueForKey:@"M"], @"message3", @"did not receive message3");
            XCTAssertEqualObjects([[values objectAtIndex:3] valueForKey:@"M"], @"message4", @"did not receive message4");
            [initialized fulfill];
        }
    };
    
    [NetworkMock prepareForOpeningResponse:@"data: initialized\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message1\", \"A\": \"12345\"}]}\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message2\", \"A\": \"12345\"}]}\n\n" then:^{
        [connection start:sse];

    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error); return;
        }
    }];
}

- (void)testTransportThrowsAnErrorIfProtocolVersionIsIncorrect{
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    
    SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    sse.serverSentEventsOperationQueue = nil;//set to nil to avoid ARC error
    
    id json = @{
        @"ConnectionId": @"10101",
        @"ConnectionToken": @"10101010101",
        @"DisconnectTimeout": @30,
        @"ProtocolVersion": @"2.0.0.0",
        @"TransportConnectTimeout": @10
    };
    [SRMockClientTransport negotiateForTransport:sse statusCode:@200 json:json];

    BOOL failed = NO;
    @try
    {
        [connection start:sse];
        XCTAssert(NO, @"Should have thrown");
    }
    @catch(NSException* e)
    {
        failed = YES;
    }
    XCTAssertEqual(YES, failed, @"We are supposed to have failed");
}

- (void)xtestTransportAutoJSONEncodesMessagesCorrectlyWhenSending {
    // This is an example of a functional test case.
    XCTAssert(NO, @"not implemented");
}

- (void)testStreamClosesCleanlyShouldReconnect {
    XCTestExpectation *initialized = [self expectationWithDescription:@"initialized"];
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    
    SRMockSSENetworkStream *NetworkMock = [[SRMockSSENetworkStream alloc] init];
    SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    [sse setServerSentEventsOperationQueue:nil];
    id json = @{
        @"ConnectionId": @"10101",
        @"ConnectionToken": @"10101010101",
        @"DisconnectTimeout": @30,
        @"ProtocolVersion": @"1.3.0.0",
        @"TransportConnectTimeout": @10
    };
    [SRMockClientTransport negotiateForTransport:sse statusCode:@200 json:json];
    
    connection.started = ^{
        [initialized fulfill];
    };
    
    [NetworkMock prepareForOpeningResponse:@"data: initialized\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}\n\n" then:^{
        [connection start:sse];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
    
    XCTestExpectation *reconnecting = [self expectationWithDescription:@"Retrying callback called"];
    connection.reconnecting = ^(){
        [reconnecting fulfill];
    };
    
    XCTestExpectation *reconnected = [self expectationWithDescription:@"Retry callback called"];
    connection.reconnected = ^(){
        [reconnected fulfill];
    };
    
    SRMockWaitBlockOperation* reconnectDelay = [[SRMockWaitBlockOperation alloc] initWithWaitTime:[[sse reconnectDelay] doubleValue]];
    [NetworkMock prepareForClose];
    [NetworkMock stopMocking];
    SRMockSSENetworkStream* NetworkReconnectMock = [[SRMockSSENetworkStream alloc]init];
    [reconnectDelay stopMocking];
    [NetworkReconnectMock prepareForOpeningResponse:^{
        reconnectDelay.afterWait();
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error){
            NSLog(@"Sub-Timeout Error: %@", error);
        }
    }];
    
    
}
@end
