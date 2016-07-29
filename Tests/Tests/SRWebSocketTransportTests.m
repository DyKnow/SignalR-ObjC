 //
//  SRWebSocketTransport.m
//  SignalR.Client.ObjC
//
//  Created by Joel Dart on 8/3/15.
//  Copyright (c) 2015 DyKnow LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SRWebSocketTransport.h"
#import <SocketRocket/SRWebSocket.h>
#import "SRConnection.h"
#import "SRConnectionInterface.h"
#import "SRNegotiationResponse.h"
#import "SRMockClientTransport+OCMock.h"
#import "SRMockWaitBlockOperation.h"
#import "SRBlockOperation.h"

@interface SRConnection (UnitTest)
@property (strong, nonatomic, readwrite) NSNumber * disconnectTimeout;
@end

@interface SRWebSocketTransport()
@property (strong, nonatomic, readwrite) SRWebSocket *webSocket;

- (void)webSocketDidOpen:(SRWebSocket *)webSocket;
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message;
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;
@end

@interface SRWebSocketTransportTests : XCTestCase

@end

@implementation SRWebSocketTransportTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


- (void) testStartCallsTheCompletionHandlerAfterSuccess {
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Handler called"];
    
    id mock = [OCMockObject niceMockForClass:[SRWebSocket class]];
    // Here we stub the alloc class method **
    [[[mock stub] andReturn:mock] alloc];
    // And we stub initWithParam: passing the param we will pass to the method to test
    [[[mock stub] andReturn:mock] initWithURLRequest:[OCMArg any]];
    [[mock stub] setDelegate: [OCMArg any]];
    [[mock stub] open];
    
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRWebSocketTransport* ws = [[ SRWebSocketTransport alloc] init];
    [ws start: connection connectionData:@"12345" completionHandler:^(id response, NSError *error){
        [expectation fulfill];
    }];
    
    [ws webSocketDidOpen: mock];
    [ws webSocket:mock didReceiveMessage:@"abcdefg"];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void) testFailureStopsAndRestartWebSocket {
    id mock = [OCMockObject niceMockForClass:[SRWebSocket class]];
    // Here we stub the alloc class method **
    [[[mock stub] andReturn:mock] alloc];
    [[[mock stub] andReturn:mock] initWithURLRequest:[OCMArg any]];
    [[mock stub] setDelegate: [OCMArg any]];
    [[mock stub] open];
    
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    connection.connectionToken = @"10101010101";
    connection.connectionId = @"10101";
    [connection changeState:disconnected toState:connected];
    
    
    SRWebSocketTransport* ws = [[ SRWebSocketTransport alloc] init];
    [ws start: connection connectionData:@"12345" completionHandler:^(id response, NSError *error){}];
    
    [ws webSocketDidOpen: mock];
    [ws webSocket:mock didReceiveMessage:@"abcdefg"];
    
    //verify we init and open another
    __block NSMutableURLRequest* request;
     mock = [OCMockObject niceMockForClass:[SRWebSocket class]];
    [[[mock stub] andReturn:mock] alloc];
    [[[mock stub] andDo:^(NSInvocation *invocation) {
        __unsafe_unretained NSMutableURLRequest *requestOut = nil;
        [invocation getArgument: &requestOut atIndex: 2];
        request = requestOut;
    }] initWithURLRequest: [OCMArg any]];
    [[mock stub] setDelegate: [OCMArg any]];
    [[mock stub] open];

    SRMockWaitBlockOperation *reconnectDelay = [[SRMockWaitBlockOperation alloc] initWithWaitTime:[[ws reconnectDelay] doubleValue]];
    [ws webSocket:mock didFailWithError:[[NSError alloc] initWithDomain:@"Unit test" code:42 userInfo:nil ]];
    [reconnectDelay.mock stopMocking];//dont want to accidentally get other blocks
    reconnectDelay.afterWait();
    XCTAssertEqual(2, reconnectDelay.waitTime, "Unexpected reconnect delay");
    XCTAssertTrue([[[request URL] absoluteString] isEqualToString:@"http://localhost:0000/reconnect?connectionData=12345&connectionToken=10101010101&transport=webSockets"], "Did not reconnect");
   }

- (void)testConnectionInitialFailureUsesCallback {
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Handler called"];
    id mock = [OCMockObject niceMockForClass:[SRWebSocket class]];
    // Here we stub the alloc class method **
    [[[mock stub] andReturn:mock] alloc];
    // And we stub initWithParam: passing the param we will pass to the method to test
    [[[mock stub] andReturn:mock] initWithURLRequest:[OCMArg any]];
    [[mock stub] setDelegate: [OCMArg any]];
    [[mock stub] open];
    [[mock expect] close];
    
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    connection.connectionToken = @"10101010101";
    connection.connectionId = @"10101";
    [connection changeState:disconnected toState:connected];
    
    SRWebSocketTransport* ws = [[ SRWebSocketTransport alloc] init];
    [ws start: connection connectionData:@"12345" completionHandler:^(id response, NSError *error){
        if (error) {
            [expectation fulfill];
        }
    }];
    
    [ws webSocketDidOpen: mock];
    [ws webSocket:mock didFailWithError:[[NSError alloc] initWithDomain:@"Unit test" code:42 userInfo:nil]];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
    [mock verify];
}

- (void)testConnectionErrorRetries_RetriesAfterADelay_CommunicatesLifeCycleViaConnection_StreamClosesUncleanly {
    __weak XCTestExpectation *initialized = [self expectationWithDescription:@"Handler called"];
    id mock = [OCMockObject niceMockForClass:[SRWebSocket class]];
    // Here we stub the alloc class method **
    [[[mock stub] andReturn:mock] alloc];
    // And we stub initWithParam: passing the param we will pass to the method to test
    [[[mock stub] andReturn:mock] initWithURLRequest:[OCMArg any]];
    [[mock stub] setDelegate: [OCMArg any]];
    [[mock stub] open];
    
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    connection.connectionToken = @"10101010101";
    connection.connectionId = @"10101";
    [connection changeState:disconnected toState:connected];
    
    __weak XCTestExpectation *reconnecting = [self expectationWithDescription:@"Retrying callback called"];
    connection.reconnecting = ^(){
        [reconnecting fulfill];
    };
    
    __weak XCTestExpectation *reconnected = [self expectationWithDescription:@"Retry callback called"];
    connection.reconnected = ^(){
        [reconnected fulfill];
    };
    
    SRWebSocketTransport* ws = [[ SRWebSocketTransport alloc] init];
    [ws start: connection connectionData:@"12345" completionHandler:^(id response, NSError *error){
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        } else {
            [initialized fulfill];
        }
    }];
    
    [ws webSocketDidOpen: mock];
    [ws webSocket:mock didReceiveMessage:@"{\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}"];
    
    SRMockWaitBlockOperation *reconnectDelay = [[SRMockWaitBlockOperation alloc] initWithWaitTime:[ws.reconnectDelay intValue]];
    [ws webSocket:mock didCloseWithCode:0 reason:@"Stream end encountered" wasClean:NO];
    [[reconnectDelay mock] stopMocking];
    reconnectDelay.afterWait();
    [ws webSocketDidOpen:mock];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testConnectionErrorRetries_RetriesAfterADelay_CommunicatesLifeCycleViaConnection_StreamClosesCleanly {
    __weak XCTestExpectation *initialized = [self expectationWithDescription:@"Handler called"];
    id mock = [OCMockObject niceMockForClass:[SRWebSocket class]];
    // Here we stub the alloc class method **
    [[[mock stub] andReturn:mock] alloc];
    // And we stub initWithParam: passing the param we will pass to the method to test
    [[[mock stub] andReturn:mock] initWithURLRequest:[OCMArg any]];
    [[mock stub] setDelegate: [OCMArg any]];
    [[mock stub] open];
    
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    connection.connectionToken = @"10101010101";
    connection.connectionId = @"10101";
    connection.transportConnectTimeout = @10;
    [connection changeState:disconnected toState:connected];
    
    __weak XCTestExpectation *reconnecting = [self expectationWithDescription:@"Retrying callback called"];
    connection.reconnecting = ^(){
        [reconnecting fulfill];
    };
    
    __weak XCTestExpectation *reconnected = [self expectationWithDescription:@"Retry callback called"];
    connection.reconnected = ^(){
        [reconnected fulfill];
    };
    
    SRWebSocketTransport* ws = [[ SRWebSocketTransport alloc] init];
    [ws start: connection connectionData:@"12345" completionHandler:^(id response, NSError *error){
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        } else {
            [initialized fulfill];
        }
    }];
    
    [ws webSocketDidOpen: mock];
    [ws webSocket:mock didReceiveMessage:@"{\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}"];
    
    SRMockWaitBlockOperation *reconnectDelay = [[SRMockWaitBlockOperation alloc] initWithWaitTime:[ws.reconnectDelay intValue]];
    [ws webSocket:mock didCloseWithCode:1001 reason:@"Somevalid reason" wasClean:YES];
    [[reconnectDelay mock] stopMocking];
    reconnectDelay.afterWait();
    [ws webSocketDidOpen:mock];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }        
    }];
    
}

- (void)testLostConnectionAbortsAllConnectionsAndReconnects {
    __weak XCTestExpectation *initialized = [self expectationWithDescription:@"Handler called"];
    id mock = [OCMockObject niceMockForClass:[SRWebSocket class]];
    // Here we stub the alloc class method **
    [[[mock stub] andReturn:mock] alloc];
    // And we stub initWithParam: passing the param we will pass to the method to test
    [[[mock stub] andReturn:mock] initWithURLRequest:[OCMArg any]];
    [[mock stub] setDelegate: [OCMArg any]];
    [[mock stub] open];
    
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    connection.connectionToken = @"10101010101";
    connection.connectionId = @"10101";
    [connection changeState:disconnected toState:connected];
    
    __weak XCTestExpectation *reconnecting = [self expectationWithDescription:@"Retrying callback called"];
    connection.reconnecting = ^(){
        [reconnecting fulfill];
    };
    
    __weak XCTestExpectation *reconnected = [self expectationWithDescription:@"Retry callback called"];
    connection.reconnected = ^(){
        [reconnected fulfill];
    };
    
    SRWebSocketTransport* ws = [[ SRWebSocketTransport alloc] init];
    [ws start: connection connectionData:@"12345" completionHandler:^(id response, NSError *error){
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        } else {
            [initialized fulfill];
        }
    }];
    
    [ws webSocketDidOpen: mock];
    [ws webSocket:mock didReceiveMessage:@"{\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}"];
    
    SRMockWaitBlockOperation *reconnectDelay = [[SRMockWaitBlockOperation alloc] initWithWaitTime:[ws.reconnectDelay intValue]];
    [ws lostConnection:connection];
    [[reconnectDelay mock] stopMocking];
    reconnectDelay.afterWait();
    [ws webSocketDidOpen:mock];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testDisconnectsOnReconnectTimeout {
    __weak XCTestExpectation *initialized = [self expectationWithDescription:@"Handler called"];
    id mock = [OCMockObject niceMockForClass:[SRWebSocket class]];
    // Here we stub the alloc class method **
    [[[mock stub] andReturn:mock] alloc];
    // And we stub initWithParam: passing the param we will pass to the method to test
    [[[mock stub] andReturn:mock] initWithURLRequest:[OCMArg any]];
    [[mock stub] setDelegate: [OCMArg any]];
    [[mock stub] open];
    
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRWebSocketTransport* ws = [[ SRWebSocketTransport alloc] init];
    id mockTransport = [OCMockObject partialMockForObject:ws];
    [SRMockClientTransport negotiateForMockTransport:mockTransport];
    
    [connection setStarted:^{
        [initialized fulfill];
    }];
    
    [connection start:ws];
    
    [ws webSocketDidOpen: mock];
    [ws webSocket:mock didReceiveMessage:@"{\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}"];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error){
            NSLog(@"Sub-Timeout Error: %@", error);
        } else {
            __weak XCTestExpectation *reconnecting = [self expectationWithDescription:@"Retrying callback called"];
            [connection setReconnecting:^{
                [reconnecting fulfill];
            }];
            
            [connection setReconnected:^{
                XCTAssert(NO, @"unexpected change!");
            }];

            __weak XCTestExpectation *closed = [self expectationWithDescription:@"Retrying callback called"];
            [connection setClosed:^{
                [closed fulfill];
            }];
            
            SRMockWaitBlockOperation *reconnectingDelay = [[SRMockWaitBlockOperation alloc] initWithWaitTime:[[ws reconnectDelay] doubleValue]];
            NSError *cancelledError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
            [ws webSocket:mock didFailWithError:cancelledError];
            [reconnectingDelay.mock stopMocking];
            SRMockWaitBlockOperation *disconnectTimeout = [[SRMockWaitBlockOperation alloc] initWithWaitTime:[[connection disconnectTimeout] doubleValue]];
            reconnectingDelay.afterWait();
            [disconnectTimeout.mock stopMocking];
            disconnectTimeout.afterWait();
            
            [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
                if (error){
                    NSLog(@"Sub-Timeout Error: %@", error);
                }
            }];
        }
    }];

}

- (void)xtestHandlesDisconnectMessageFromConnection {
    // This is an example of a functional test case.
    XCTAssert(NO, @"not implemented");
}

- (void)testTransportCanTimeoutWhenItDoesNotReceiveInitializeMessage {
    __weak XCTestExpectation *initialized = [self expectationWithDescription:@"Handler called"];
    id mock = [OCMockObject niceMockForClass:[SRWebSocket class]];
    // Here we stub the alloc class method **
    [[[mock stub] andReturn:mock] alloc];
    // And we stub initWithParam: passing the param we will pass to the method to test
    [[[mock stub] andReturn:mock] initWithURLRequest:[OCMArg any]];
    [[mock stub] setDelegate: [OCMArg any]];
    [[mock stub] open];
    [[mock expect] close];
    
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];

    SRWebSocketTransport* ws = [[ SRWebSocketTransport alloc] init];
    id mockTransport = [OCMockObject partialMockForObject:ws];
    [SRMockClientTransport negotiateForMockTransport:mockTransport];
    
    connection.started = ^{
        XCTAssert(NO, @"Connection started");
    };
    
    connection.error = ^(NSError *error){
        [initialized fulfill];
    };
    
    SRMockWaitBlockOperation* transportConnectTimeout = [[SRMockWaitBlockOperation alloc]initWithBlockOperationClass:[SRTransportConnectTimeoutBlockOperation class]];
    [connection start:ws];
    [transportConnectTimeout.mock stopMocking];
    transportConnectTimeout.afterWait();
        
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
    [mock verify];
}

- (void)testStart_Stop_StartTriggersTheCorrectCallbacks {
    __weak XCTestExpectation *initialized = [self expectationWithDescription:@"Handler called"];
    id mock = [OCMockObject niceMockForClass:[SRWebSocket class]];
    // Here we stub the alloc class method **
    [[[mock stub] andReturn:mock] alloc];
    // And we stub initWithParam: passing the param we will pass to the method to test
    [[[mock stub] andReturn:mock] initWithURLRequest:[OCMArg any]];
    [[mock stub] setDelegate: [OCMArg any]];
    [[mock stub] open];
    
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRWebSocketTransport* ws = [[ SRWebSocketTransport alloc] init];
    id mockTransport = [OCMockObject partialMockForObject:ws];
    [SRMockClientTransport negotiateForMockTransport:mockTransport];
    
    __block BOOL firstErrorFailedCalled = NO;
    __block int startCount = 0;
    
    connection.started = ^{
        startCount++;
        [initialized fulfill];
        XCTAssertTrue(firstErrorFailedCalled, @"only get started after the error fails first");
    };
    
    connection.closed = ^{
        firstErrorFailedCalled = YES;
    };
    
    connection.error = ^(NSError *error){
        XCTAssert(NO, @"errors might be expected in the promise but not for the callbacks");
    };
    
    [connection start:ws];
    [connection stop];
    [connection start:ws];
    
    [ws webSocketDidOpen: mock];
    [ws webSocket:mock didReceiveMessage:@"{\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}"];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
        XCTAssert(startCount == 1, @"expected exactly one started callback");
    }];
}

- (void)xtestPingIntervalStopsTheConnectionOn401s {
    __weak XCTestExpectation *initialized = [self expectationWithDescription:@"Handler called"];
    id mock = [OCMockObject niceMockForClass:[SRWebSocket class]];
    // Here we stub the alloc class method **
    [[[mock stub] andReturn:mock] alloc];
    // And we stub initWithParam: passing the param we will pass to the method to test
    [[[mock stub] andReturn:mock] initWithURLRequest:[OCMArg any]];
    [[mock stub] setDelegate: [OCMArg any]];
    [[mock stub] open];
    
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRWebSocketTransport* ws = [[ SRWebSocketTransport alloc] init];
    id mockTransport = [OCMockObject partialMockForObject:ws];
    [SRMockClientTransport negotiateForMockTransport:mockTransport];
    
    connection.error = ^(NSError *error){
        [initialized fulfill];
        XCTAssert(NO, @"todo: verify it's a 401");
    };
    
    [connection start:ws];
    
    [ws webSocketDidOpen: mock];
    [ws webSocket:mock didReceiveMessage:@"{\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}"];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)xtestPingIntervalStopsTheConnectionOn403s {
    __weak XCTestExpectation *initialized = [self expectationWithDescription:@"Handler called"];
    id mock = [OCMockObject niceMockForClass:[SRWebSocket class]];
    // Here we stub the alloc class method **
    [[[mock stub] andReturn:mock] alloc];
    // And we stub initWithParam: passing the param we will pass to the method to test
    [[[mock stub] andReturn:mock] initWithURLRequest:[OCMArg any]];
    [[mock stub] setDelegate: [OCMArg any]];
    [[mock stub] open];
    
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRWebSocketTransport* ws = [[ SRWebSocketTransport alloc] init];
    id mockTransport = [OCMockObject partialMockForObject:ws];
    [SRMockClientTransport negotiateForMockTransport:mockTransport];
    
    connection.error = ^(NSError *error){
        [initialized fulfill];
        XCTAssert(NO, @"todo: verify it's a 403");
    };
    
    [connection start:ws];
    
    [ws webSocketDidOpen: mock];
    [ws webSocket:mock didReceiveMessage:@"{\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}"];
    
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

- (void)testConnectionCanBeStoppedDuringTransportStart {
    __weak XCTestExpectation *initialized = [self expectationWithDescription:@"Handler called"];
    id mock = [OCMockObject niceMockForClass:[SRWebSocket class]];
    // Here we stub the alloc class method **
    [[[mock stub] andReturn:mock] alloc];
    // And we stub initWithParam: passing the param we will pass to the method to test
    [[[mock stub] andReturn:mock] initWithURLRequest:[OCMArg any]];
    [[mock stub] setDelegate: [OCMArg any]];
    [[mock stub] open];
    
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRWebSocketTransport* ws = [[ SRWebSocketTransport alloc] init];
    id mockTransport = [OCMockObject partialMockForObject:ws];
    [SRMockClientTransport negotiateForMockTransport:mockTransport];
    
    connection.closed = ^{
        [initialized fulfill];
    };
    
    connection.error = ^(NSError* err){
        XCTAssert(NO, @"Error was triggered");
    };
    
    connection.started = ^(){
        XCTAssert(NO, @"start was triggered");
    };
    
    [connection start:ws];
    
    [ws webSocketDidOpen: mock];
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
    __weak XCTestExpectation *initialized = [self expectationWithDescription:@"Handler called"];
    id mock = [OCMockObject niceMockForClass:[SRWebSocket class]];
    // Here we stub the alloc class method **
    [[[mock stub] andReturn:mock] alloc];
    // And we stub initWithParam: passing the param we will pass to the method to test
    [[[mock stub] andReturn:mock] initWithURLRequest:[OCMArg any]];
    [[mock stub] setDelegate: [OCMArg any]];
    [[mock stub] open];
    [[mock stub] send:[OCMArg any]];
    
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRWebSocketTransport* ws = [[ SRWebSocketTransport alloc] init];
    id mockTransport = [OCMockObject partialMockForObject:ws];
    [SRMockClientTransport negotiateForMockTransport:mockTransport];
    
    __block NSMutableArray* values = [[NSMutableArray alloc] init];
    
    __weak __typeof(&*connection)weakConnection = connection;
    __weak __typeof(&*ws)weakWs = ws;
    connection.started = ^(){
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        __strong __typeof(&*weakWs)strongWs = weakWs;
        [strongConnection send:@"test" completionHandler:^(id response, NSError *error) {
            //after sending receive two more
            [strongWs webSocket:mock didReceiveMessage:@"{\"M\":[{\"H\":\"hubname\", \"M\":\"message3\", \"A\": \"12345\"}]}"];
            [strongWs webSocket:mock didReceiveMessage:@"{\"M\":[{\"H\":\"hubname\", \"M\":\"message4\", \"A\": \"12345\"}]}"];
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
    
    [connection start:ws];
    
    [ws webSocketDidOpen: mock];
    [ws webSocket:mock didReceiveMessage:@"{\"M\":[{\"H\":\"hubname\", \"M\":\"message1\", \"A\": \"12345\"}, {\"H\":\"hubname\", \"M\":\"message2\", \"A\": \"12345\"}]}"];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error); return;
        }
    }];
}

@end
