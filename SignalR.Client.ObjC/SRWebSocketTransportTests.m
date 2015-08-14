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
            [ws lostConnection:strongConnection];
            
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

- (void)testDisconnectsOnReconnectTimeout {
    XCTestExpectation *initialized = [self expectationWithDescription:@"Handler called"];
    id mock = [OCMockObject niceMockForClass:[SRWebSocket class]];
    // Here we stub the alloc class method **
    [[[mock stub] andReturn:mock] alloc];
    // And we stub initWithParam: passing the param we will pass to the method to test
    [[[mock stub] andReturn:mock] initWithURLRequest:[OCMArg any]];
    [[mock stub] setDelegate: [OCMArg any]];
    [[mock stub] open];
    
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRWebSocketTransport* ws = [[ SRWebSocketTransport alloc] init];
    
    id pmock = [OCMockObject partialMockForObject: ws];
    [[[pmock stub] andDo:^(NSInvocation *invocation) {
        void (^ callbackOut)(SRNegotiationResponse * response, NSError *error);
        __unsafe_unretained void (^successCallback)(SRNegotiationResponse *response, NSError *error) = nil;
        [invocation getArgument: &successCallback atIndex: 4];
        callbackOut = successCallback;
        callbackOut([[SRNegotiationResponse alloc ]initWithDictionary:@{
                                                                        @"ConnectionId": @"10101",
                                                                        @"ConnectionToken": @"10101010101",
                                                                        @"DisconnectTimeout": @30,
                                                                        @"ProtocolVersion": @"1.3.0.0"
                                                                        }], nil);
    }] negotiate:[OCMArg any] connectionData:[OCMArg any] completionHandler:[OCMArg any]];

    
    [connection setStarted:^{
        [initialized fulfill];
    }];
    
    [connection start:ws];
    
    [ws webSocketDidOpen: mock];
    [ws webSocket:mock didReceiveMessage:@"data: initialized\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}\n\n"];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error){
            NSLog(@"Sub-Timeout Error: %@", error);
        } else {
            XCTestExpectation *reconnecting = [self expectationWithDescription:@"Retrying callback called"];
            [connection setReconnecting:^{
                [reconnecting fulfill];
            }];
            
            NSError *cancelledError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
            [ws webSocket:mock didFailWithError:cancelledError];
            
            [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
                if (error){
                    NSLog(@"Sub-Timeout Error: %@", error);
                } else {
                    [connection setReconnected:^{
                        XCTAssert(NO, @"unexpected change!");
                    }];
                    XCTestExpectation *closed = [self expectationWithDescription:@"Retrying callback called"];
                    [connection setClosed:^{
                        [closed fulfill];
                    }];
                    
                    //TODO: Timeout Reconnect, wait 2 seconds.
                    //BUG: WebsocketsTransport does not use the _reconnectDelay
                    
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

- (void)testHandlesAbortFromConnection {
    // This is an example of a functional test case.
    XCTAssert(NO, @"not implemented");
}

- (void)testTransportCanTimeoutWhenItDoesNotReceiveInitializeMessage {
    XCTestExpectation *initialized = [self expectationWithDescription:@"Handler called"];
    id mock = [OCMockObject niceMockForClass:[SRWebSocket class]];
    // Here we stub the alloc class method **
    [[[mock stub] andReturn:mock] alloc];
    // And we stub initWithParam: passing the param we will pass to the method to test
    [[[mock stub] andReturn:mock] initWithURLRequest:[OCMArg any]];
    [[mock stub] setDelegate: [OCMArg any]];
    [[mock stub] open];
    
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRWebSocketTransport* ws = [[ SRWebSocketTransport alloc] init];
    
    id pmock = [OCMockObject partialMockForObject: ws];
    [[[pmock stub] andDo:^(NSInvocation *invocation) {
        void (^ callbackOut)(SRNegotiationResponse * response, NSError *error);
        __unsafe_unretained void (^successCallback)(SRNegotiationResponse *response, NSError *error) = nil;
        [invocation getArgument: &successCallback atIndex: 4];
        callbackOut = successCallback;
        callbackOut([[SRNegotiationResponse alloc ]initWithDictionary:@{
                                                                        @"ConnectionId": @"10101",
                                                                        @"ConnectionToken": @"10101010101",
                                                                        @"DisconnectTimeout": @30,
                                                                        @"ProtocolVersion": @"1.3.0.0",
                                                                        @"TransportConnectTimeout": @10
                                                                        }], nil);
    }] negotiate:[OCMArg any] connectionData:[OCMArg any] completionHandler:[OCMArg any]];
    
    connection.started = ^{
        XCTAssert(NO, @"Connection started");
    };
    
    connection.error = ^(NSError *error){
        [initialized fulfill];
    };
    
    [connection start:ws];
    
    [ws webSocketDidOpen: mock];
    [ws webSocket:mock didReceiveMessage:@""];
    
    //TODO: Wait for Disconnect...
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];}

- (void)testStart_Stop_StartTriggersTheCorrectCallbacks {
    XCTestExpectation *initialized = [self expectationWithDescription:@"Handler called"];
    id mock = [OCMockObject niceMockForClass:[SRWebSocket class]];
    // Here we stub the alloc class method **
    [[[mock stub] andReturn:mock] alloc];
    // And we stub initWithParam: passing the param we will pass to the method to test
    [[[mock stub] andReturn:mock] initWithURLRequest:[OCMArg any]];
    [[mock stub] setDelegate: [OCMArg any]];
    [[mock stub] open];
    
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRWebSocketTransport* ws = [[ SRWebSocketTransport alloc] init];
    
    id pmock = [OCMockObject partialMockForObject: ws];
    [[[pmock stub] andDo:^(NSInvocation *invocation) {
        void (^ callbackOut)(SRNegotiationResponse * response, NSError *error);
        __unsafe_unretained void (^successCallback)(SRNegotiationResponse *response, NSError *error) = nil;
        [invocation getArgument: &successCallback atIndex: 4];
        callbackOut = successCallback;
        callbackOut([[SRNegotiationResponse alloc ]initWithDictionary:@{
                                                                        @"ConnectionId": @"10101",
                                                                        @"ConnectionToken": @"10101010101",
                                                                        @"DisconnectTimeout": @30,
                                                                        @"ProtocolVersion": @"1.3.0.0"
                                                                        }], nil);
    }] negotiate:[OCMArg any] connectionData:[OCMArg any] completionHandler:[OCMArg any]];
    
    __block BOOL firstErrorFailedCalled = NO;
    __block int startCount = 0;
    
    connection.started = ^{
        startCount++;
        [initialized fulfill];
        XCTAssertTrue(firstErrorFailedCalled, @"only get started after the error fails first");
    };
    
    connection.error = ^(NSError *error){
        firstErrorFailedCalled = YES;
    };
    
    [connection start:ws];
    [connection stop];
    [connection start:ws];
    
    [ws webSocketDidOpen: mock];
    [ws webSocket:mock didReceiveMessage:@"data: initialized\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}\n\n"];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
        XCTAssert(startCount == 1, @"expected exactly one started callback");
    }];
}

- (void)xtestPingIntervalStopsTheConnectionOn401s {
    XCTestExpectation *initialized = [self expectationWithDescription:@"Handler called"];
    id mock = [OCMockObject niceMockForClass:[SRWebSocket class]];
    // Here we stub the alloc class method **
    [[[mock stub] andReturn:mock] alloc];
    // And we stub initWithParam: passing the param we will pass to the method to test
    [[[mock stub] andReturn:mock] initWithURLRequest:[OCMArg any]];
    [[mock stub] setDelegate: [OCMArg any]];
    [[mock stub] open];
    
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRWebSocketTransport* ws = [[ SRWebSocketTransport alloc] init];
    
    id pmock = [OCMockObject partialMockForObject: ws];
    [[[pmock stub] andDo:^(NSInvocation *invocation) {
        void (^ callbackOut)(SRNegotiationResponse * response, NSError *error);
        __unsafe_unretained void (^successCallback)(SRNegotiationResponse *response, NSError *error) = nil;
        [invocation getArgument: &successCallback atIndex: 4];
        callbackOut = successCallback;
        callbackOut([[SRNegotiationResponse alloc ]initWithDictionary:@{
                                                                        @"ConnectionId": @"10101",
                                                                        @"ConnectionToken": @"10101010101",
                                                                        @"DisconnectTimeout": @30,
                                                                        @"ProtocolVersion": @"1.3.0.0",
                                                                        @"TransportConnectTimeout": @10
                                                                        }], nil);
    }] negotiate:[OCMArg any] connectionData:[OCMArg any] completionHandler:[OCMArg any]];
    
    connection.error = ^(NSError *error){
        [initialized fulfill];
        XCTAssert(NO, @"todo: verify it's a 401");
    };
    
    [connection start:ws];
    
    [ws webSocketDidOpen: mock];
    [ws webSocket:mock didReceiveMessage:@"data: initialized\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}\n\n"];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)xtestPingIntervalStopsTheConnectionOn403s {
    XCTestExpectation *initialized = [self expectationWithDescription:@"Handler called"];
    id mock = [OCMockObject niceMockForClass:[SRWebSocket class]];
    // Here we stub the alloc class method **
    [[[mock stub] andReturn:mock] alloc];
    // And we stub initWithParam: passing the param we will pass to the method to test
    [[[mock stub] andReturn:mock] initWithURLRequest:[OCMArg any]];
    [[mock stub] setDelegate: [OCMArg any]];
    [[mock stub] open];
    
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRWebSocketTransport* ws = [[ SRWebSocketTransport alloc] init];
    
    id pmock = [OCMockObject partialMockForObject: ws];
    [[[pmock stub] andDo:^(NSInvocation *invocation) {
        void (^ callbackOut)(SRNegotiationResponse * response, NSError *error);
        __unsafe_unretained void (^successCallback)(SRNegotiationResponse *response, NSError *error) = nil;
        [invocation getArgument: &successCallback atIndex: 4];
        callbackOut = successCallback;
        callbackOut([[SRNegotiationResponse alloc ]initWithDictionary:@{
                                                                        @"ConnectionId": @"10101",
                                                                        @"ConnectionToken": @"10101010101",
                                                                        @"DisconnectTimeout": @30,
                                                                        @"ProtocolVersion": @"1.3.0.0",
                                                                        @"TransportConnectTimeout": @10
                                                                        }], nil);
    }] negotiate:[OCMArg any] connectionData:[OCMArg any] completionHandler:[OCMArg any]];
    
    connection.error = ^(NSError *error){
        [initialized fulfill];
        XCTAssert(NO, @"todo: verify it's a 403");
    };
    
    [connection start:ws];
    
    [ws webSocketDidOpen: mock];
    [ws webSocket:mock didReceiveMessage:@"data: initialized\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}\n\n"];
    
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

- (void)testConnectionDataFlowsWithAllRequestsToServer {
    // This is an example of a functional test case.
    XCTAssert(NO, @"not implemented");
}

- (void)testReconnectExceedingTheReconnectWindowResultsInTheConnectionDisconnect {
    [self testDisconnectsOnReconnectTimeout];
}

- (void)testConnectionCanBeStoppedDuringTransportStart {
    XCTestExpectation *initialized = [self expectationWithDescription:@"Handler called"];
    id mock = [OCMockObject niceMockForClass:[SRWebSocket class]];
    // Here we stub the alloc class method **
    [[[mock stub] andReturn:mock] alloc];
    // And we stub initWithParam: passing the param we will pass to the method to test
    [[[mock stub] andReturn:mock] initWithURLRequest:[OCMArg any]];
    [[mock stub] setDelegate: [OCMArg any]];
    [[mock stub] open];
    
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRWebSocketTransport* ws = [[ SRWebSocketTransport alloc] init];
    
    id pmock = [OCMockObject partialMockForObject: ws];
    [[[pmock stub] andDo:^(NSInvocation *invocation) {
        void (^ callbackOut)(SRNegotiationResponse * response, NSError *error);
        __unsafe_unretained void (^successCallback)(SRNegotiationResponse *response, NSError *error) = nil;
        [invocation getArgument: &successCallback atIndex: 4];
        callbackOut = successCallback;
        callbackOut([[SRNegotiationResponse alloc ]initWithDictionary:@{
                                                                        @"ConnectionId": @"10101",
                                                                        @"ConnectionToken": @"10101010101",
                                                                        @"DisconnectTimeout": @30,
                                                                        @"ProtocolVersion": @"1.3.0.0",
                                                                        }], nil);
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
    
    [connection start:ws];
    
    [ws webSocketDidOpen: mock];
    //gets the response but has not completed intialize
    [ws webSocket:mock didReceiveMessage:@""];
    [connection stop];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error); return;
        }
        XCTAssertEqual(connection.state, disconnected, @"Connection was not disconnected");
        XCTAssertEqual(connection.transport, nil, @"Transport was not cleared after stop");
    }];
}

- (void)testConnectionCanBeStoppedPriorToTransportState {
    XCTestExpectation *initialized = [self expectationWithDescription:@"Handler called"];
    id mock = [OCMockObject niceMockForClass:[SRWebSocket class]];
    // Here we stub the alloc class method **
    [[[mock stub] andReturn:mock] alloc];
    // And we stub initWithParam: passing the param we will pass to the method to test
    [[[mock stub] andReturn:mock] initWithURLRequest:[OCMArg any]];
    [[mock stub] setDelegate: [OCMArg any]];
    [[mock stub] open];
    
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRWebSocketTransport* ws = [[ SRWebSocketTransport alloc] init];
    
    id pmock = [OCMockObject partialMockForObject: ws];
    [[[pmock stub] andDo:^(NSInvocation *invocation) {
        void (^ callbackOut)(SRNegotiationResponse * response, NSError *error);
        __unsafe_unretained void (^successCallback)(SRNegotiationResponse *response, NSError *error) = nil;
        [invocation getArgument: &successCallback atIndex: 4];
        callbackOut = successCallback;
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
    
    [connection start:ws];
    [connection stop];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
        XCTAssertEqual(connection.state, disconnected, @"Connection was not disconnected");
        XCTAssertEqual(connection.transport, nil, @"Transport was not cleared after stop");
    }];

}

- (void)testTransportCanSendAndReceiveMessagesOnConnect {
    XCTestExpectation *initialized = [self expectationWithDescription:@"Handler called"];
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
    
    id pmock = [OCMockObject partialMockForObject: ws];
    [[[pmock stub] andDo:^(NSInvocation *invocation) {
        void (^ callbackOut)(SRNegotiationResponse * response, NSError *error);
        __unsafe_unretained void (^successCallback)(SRNegotiationResponse *response, NSError *error) = nil;
        [invocation getArgument: &successCallback atIndex: 4];
        callbackOut = successCallback;
        callbackOut([[SRNegotiationResponse alloc ]initWithDictionary:@{
                                                                        @"ConnectionId": @"10101",
                                                                        @"ConnectionToken": @"10101010101",
                                                                        @"DisconnectTimeout": @30,
                                                                        @"ProtocolVersion": @"1.3.0.0",
                                                                        }], nil);
    }] negotiate:[OCMArg any] connectionData:[OCMArg any] completionHandler:[OCMArg any]];

    __block NSMutableArray* values = [[NSMutableArray alloc] init];
    
    __weak __typeof(&*connection)weakConnection = connection;
    __weak __typeof(&*ws)weakWs = ws;
    connection.started = ^(){
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        __strong __typeof(&*weakWs)strongWs = weakWs;
        [strongConnection send:@"test" completionHandler:^(id response, NSError *error) {
            //after sending receive two more
            [strongWs webSocket:mock didReceiveMessage:@"data: {\"M\":[{\"H\":\"hubname\", \"M\":\"message3\", \"A\": \"12345\"}]}\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message4\", \"A\": \"12345\"}]}\n\n"];
            
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
    [ws webSocket:mock didReceiveMessage:@"data: initialized\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message1\", \"A\": \"12345\"}]}\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message2\", \"A\": \"12345\"}]}\n\n"];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error); return;
        }
    }];
}

- (void)testTransportThrowsAnErrorIfProtocolVersionIsIncorrect{
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRWebSocketTransport* ws = [[ SRWebSocketTransport alloc] init];
    
    id pmock = [OCMockObject partialMockForObject: ws];
    [[[pmock stub] andDo:^(NSInvocation *invocation) {
        __unsafe_unretained void (^ callbackOut)(SRNegotiationResponse * response, NSError *error);
        [invocation getArgument: &callbackOut atIndex: 4];
        callbackOut([[SRNegotiationResponse alloc ]
                     initWithDictionary:@{
                                          @"ConnectionId": @"10101",
                                          @"ConnectionToken": @"10101010101",
                                          @"DisconnectTimeout": @30,
                                          @"ProtocolVersion": @"2.0.0.0"
                                          }], nil);
    }] negotiate:[OCMArg any] connectionData:[OCMArg any] completionHandler:[OCMArg any]];
    [[[pmock stub] andDo:^(NSInvocation * invocation) {
        __unsafe_unretained void (^ callbackOut)(id * response, NSError *error);
        [invocation getArgument: &callbackOut atIndex: 5];
        callbackOut(nil, nil);//SSE just falls back to httpbase, just verify we are allowed through
    }] send:[OCMArg any]  data:[OCMArg any] connectionData:[OCMArg any] completionHandler:[OCMArg any]];
    
    BOOL failed = NO;
    @try
    {
        [connection start:ws];
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

@end
