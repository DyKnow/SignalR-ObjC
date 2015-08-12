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
    XCTestExpectation *expectation = [self expectationWithDescription:@"Handler called"];
    
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

    [ws webSocket:mock didFailWithError:[[NSError alloc] initWithDomain:@"Unit test" code:42 userInfo:nil ]];
    XCTAssertTrue([[[request URL] absoluteString] isEqualToString:@"http://localhost:0000/reconnect?connectionData=12345&connectionToken=10101010101&groupsToken=&messageId=&transport=webSockets"], "Did not reconnect");
   }

- (void)testConnectionInitialFailureUsesCallback {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Handler called"];
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
}

- (void)testConnectionErrorRetries_RetriesAfterADelay_CommunicatesLifeCycleViaConnection_StreamClosesUncleanly {
    XCTestExpectation *initialized = [self expectationWithDescription:@"Handler called"];
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
    
    SRWebSocketTransport* ws = [[ SRWebSocketTransport alloc] init];
    [ws start: connection connectionData:@"12345" completionHandler:^(id response, NSError *error){
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        } else {
            [initialized fulfill];
        }
    }];
    
    [ws webSocketDidOpen: mock];
    [ws webSocket:mock didReceiveMessage:@"data: initialized\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}\n\n"];
    
    __weak __typeof(&*connection)weakConnection = connection;
    __weak __typeof(&*self)weakSelf = self;
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        } else {
            __strong __typeof(&*weakSelf)strongSelf = weakSelf;
            __strong __typeof(&*weakConnection)strongConnection = weakConnection;
            XCTestExpectation *reconnecting = [strongSelf expectationWithDescription:@"Retrying callback called"];
            strongConnection.reconnecting = ^(){
                [reconnecting fulfill];
            };
            [ws webSocket:mock didCloseWithCode:0 reason:@"Stream end encountered" wasClean:NO];

            [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
                if (error){
                    NSLog(@"Sub-Timeout Error: %@", error);
                } else {
                    XCTestExpectation *reconnected = [strongSelf expectationWithDescription:@"Retry callback called"];
                    strongConnection.reconnected = ^(){
                        [reconnected fulfill];
                    };
                    [ws webSocketDidOpen:mock];
                    
                    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
                        if (error){
                            NSLog(@"Sub-Timeout Error: %@", error);
                        }
                    }];
                }
            }];
        }
        
    }];
}

- (void)testConnectionErrorRetries_RetriesAfterADelay_CommunicatesLifeCycleViaConnection_StreamClosesCleanly {
    XCTestExpectation *initialized = [self expectationWithDescription:@"Handler called"];
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
    
    SRWebSocketTransport* ws = [[ SRWebSocketTransport alloc] init];
    [ws start: connection connectionData:@"12345" completionHandler:^(id response, NSError *error){
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        } else {
            [initialized fulfill];
        }
    }];
    
    [ws webSocketDidOpen: mock];
    [ws webSocket:mock didReceiveMessage:@"data: initialized\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}\n\n"];
    
    __weak __typeof(&*connection)weakConnection = connection;
    __weak __typeof(&*self)weakSelf = self;
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        } else {
            __strong __typeof(&*weakSelf)strongSelf = weakSelf;
            __strong __typeof(&*weakConnection)strongConnection = weakConnection;
            XCTestExpectation *reconnecting = [strongSelf expectationWithDescription:@"Retrying callback called"];
            strongConnection.reconnecting = ^(){
                [reconnecting fulfill];
            };
            [ws webSocket:mock didCloseWithCode:1001 reason:@"Somevalid reason" wasClean:YES];
            
            [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
                if (error){
                    NSLog(@"Sub-Timeout Error: %@", error);
                } else {
                    XCTestExpectation *reconnected = [strongSelf expectationWithDescription:@"Retry callback called"];
                    strongConnection.reconnected = ^(){
                        [reconnected fulfill];
                    };
                    [ws webSocketDidOpen:mock];
                    
                    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
                        if (error){
                            NSLog(@"Sub-Timeout Error: %@", error);
                        }
                    }];
                }
            }];
        }
        
    }];
    
}

- (void)testLostConnectionAbortsAllConnectionsAndReconnects {
    // This is an example of a functional test case.
    XCTAssert(NO, @"not implemented");
}

- (void)testDisconnectsOnReconnectTimeout {
    // This is an example of a functional test case.
    XCTAssert(NO, @"not implemented");
}

- (void)testHandlesAbortFromConnection {
    // This is an example of a functional test case.
    XCTAssert(NO, @"not implemented");
}

- (void)testTransportCanTimeoutWhenItDoesNotReceiveInitializeMessage {
    // This is an example of a functional test case.
    XCTAssert(NO, @"not implemented");
}

- (void)testStart_Stop_StartTriggersTheCorrectCallbacks {
    // This is an example of a functional test case.
    XCTAssert(NO, @"not implemented");
}

- (void)testPingIntervalStopsTheConnectionOn401s {
    // This is an example of a functional test case.
    XCTAssert(NO, @"not implemented");
}

- (void)testPingIntervalStopsTheConnectionOn403s {
    // This is an example of a functional test case.
    XCTAssert(NO, @"not implemented");
}

- (void)testPingIntervalBehavesAppropriately {
    // This is an example of a functional test case.
    XCTAssert(NO, @"not implemented");
}

- (void)testConnectionDataFlowsWithAllRequestsToServer {
    // This is an example of a functional test case.
    XCTAssert(NO, @"not implemented");
}

- (void)testReconnectExceedingTheReconnectWindowResultsInTheConnectionDisconnect {
    // This is an example of a functional test case.
    XCTAssert(NO, @"not implemented");
}

- (void)testConnectionCanBeStoppedDuringTransportStart {
    // This is an example of a functional test case.
    XCTAssert(NO, @"not implemented");
}

- (void)testConnectionCanBeStoppedPriorToTransportState {
    // This is an example of a functional test case.
    XCTAssert(NO, @"not implemented");
}

- (void)testTransportCanSendAndReceiveMessagesOnConnect {
    // This is an example of a functional test case.
    XCTAssert(NO, @"not implemented");
}

- (void)testTransportThrowsAnErrorIfProtocolVersionIsIncorrect{
    // This is an example of a functional test case.
    XCTAssert(NO, @"not implemented");
}

- (void)testTransportAutoJSONEncodesMessagesCorrectlyWhenSending {
    // This is an example of a functional test case.
    XCTAssert(NO, @"not implemented");
}

@end
