//
//  SRLongPollingTransport.m
//  SignalR.Client.ObjC
//
//  Created by Joel Dart on 8/4/15.
//  Copyright (c) 2015 DyKnow LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <AFNetworking/AFNetworking.h>
#import "SRLongPollingTransport.h"
#import "SRConnection.h"
#import "SRConnectionInterface.h"
#import "SRNegotiationResponse.h"
#import "SRMockNetwork.h"

@interface SRLongPollingTransport ()
@property (strong, nonatomic, readwrite) NSOperationQueue *pollingOperationQueue;

- (void)poll:(id<SRConnectionInterface>)connection connectionData:(NSString *)connectionData completionHandler:(void (^)(id response, NSError *error))block;

@end

@interface LP_WaitBlock: NSObject
@property (readwrite, nonatomic, copy) void (^afterWait)();
@property (readwrite, nonatomic, assign) double waitTime;
@property (readwrite, nonatomic, strong) id mock;
@end

@implementation LP_WaitBlock
- (id) init: (int)expectedWait{
    self = [super init];
    __weak __typeof(&*self)weakSelf = self;
    _afterWait = nil;
    _mock = [OCMockObject mockForClass:[NSBlockOperation class]];
    [[[[_mock stub] andReturn: _mock ] andDo:^(NSInvocation *invocation) {
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        __unsafe_unretained void (^successCallback)() = nil;
        [invocation getArgument: &successCallback atIndex: 2];
        strongSelf.afterWait = successCallback;
    }] blockOperationWithBlock: [OCMArg any]];
    [[[_mock stub] andDo:^(NSInvocation *invocation) {
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        double delay = 0;
        [invocation getArgument: &delay atIndex:4];
        strongSelf.waitTime = delay;
    }] performSelector:@selector(start) withObject:nil afterDelay: expectedWait];
    return self;
}

- (void)dealloc {
    [_mock stopMocking];
}

@end

@interface SRLongPollingTransportTests : XCTestCase

@end

@implementation SRLongPollingTransportTests

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

    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    connection.connectionToken = @"10101010101";
    connection.connectionId = @"10101";
    [connection changeState:disconnected toState:connected];
    
    SRLongPollingTransport* lp = [[ SRLongPollingTransport alloc] init];
    lp.pollingOperationQueue = nil;//set to nil to get around weird ARC OCMock bugs http://stackoverflow.com/questions/18121902/using-ocmock-on-nsoperation-gives-bad-access

    id connect = [SRMockNetwork mockHttpRequestOperationForClass:[AFHTTPRequestOperation class]
                                                      statusCode:@200
                                                  responseString:@"abcdefg"];
    
    id mockTransport = [OCMockObject partialMockForObject:lp];
    [[[mockTransport stub] andForwardToRealObject] poll:[OCMArg any] connectionData:[OCMArg any] completionHandler:[OCMArg isNotNil]];
    [[[mockTransport stub] andDo:^(NSInvocation * invocation) {
        //By Design LP will poll immediately when getting data.  We dont care about the second poll so lets just eat it here.
    }] poll:[OCMArg any] connectionData:[OCMArg any] completionHandler:[OCMArg isNil]];

    [lp start: connection connectionData:@"12345" completionHandler:^(id response, NSError *error){
        [expectation fulfill];
    }];
    [connect stopMocking];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void) testFailureStopsAndRestartLongPolling {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRLongPollingTransport* lp = [[ SRLongPollingTransport alloc] init];
    
    id pmock = [OCMockObject partialMockForObject: lp];
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
    
    id connect1 = [SRMockNetwork mockHttpRequestOperationForClass:[AFHTTPRequestOperation class]
                                                       statusCode:@500
                                                            error:[[NSError alloc] initWithDomain:@"Unit test" code:42 userInfo:nil]];
    lp.pollingOperationQueue = nil; //set to nil to get around weird ARC OCMock bugs http://stackoverflow.com/questions/18121902/using-ocmock-on-nsoperation-gives-bad-access
    LP_WaitBlock *errorDelay = [[LP_WaitBlock alloc] init:[lp.errorDelay doubleValue]];
    [connection start:lp];
    [connect1 stopMocking];
    [errorDelay.mock stopMocking];
    
    __block NSMutableURLRequest* request;
    id connect2 = [OCMockObject niceMockForClass:[AFHTTPRequestOperation class]];
    [[[connect2 stub] andReturn:connect2] alloc];
    [[[connect2 stub] andDo:^(NSInvocation *invocation) {
        __unsafe_unretained NSMutableURLRequest *requestOut = nil;
        [invocation getArgument: &requestOut atIndex: 2];
        request = requestOut;
    }] initWithRequest:[OCMArg any]];
    errorDelay.afterWait();
    XCTAssertEqual([lp.errorDelay doubleValue], errorDelay.waitTime, "Unexpected reconnect delay");
    XCTAssertTrue([[[request URL] absoluteString] isEqualToString:@"http://localhost:0000/connect?connectionData=&connectionToken=10101010101&groupsToken=&messageId=&transport=longPolling"], "Did not reconnect");
}

- (void)testConnectionInitialNotCancelledPollsAgainAfterDelay {
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRLongPollingTransport* lp = [[ SRLongPollingTransport alloc] init];
    
    id mockTransport = [OCMockObject partialMockForObject: lp];
    [[[mockTransport stub] andDo:^(NSInvocation *invocation) {
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
    
    [[[mockTransport stub] andForwardToRealObject] poll:[OCMArg any] connectionData:[OCMArg isNil] completionHandler:[OCMArg isNotNil]];
    [[[mockTransport stub] andDo:^(NSInvocation * invocation) {
        //By Design LP will poll immediately when getting data.  We dont care about the second poll so lets just eat it here.
    }] poll:[OCMArg any] connectionData:[OCMArg isNil] completionHandler:[OCMArg isNil]];
    
    id connect = [SRMockNetwork mockHttpRequestOperationForClass:[AFHTTPRequestOperation class]
                                                      statusCode:@500
                                                           error:[[NSError alloc] initWithDomain:@"EXPECTED" code:NSURLErrorTimedOut userInfo:nil]];
    lp.pollingOperationQueue = nil; //set to nil to get around weird ARC OCMock bugs http://stackoverflow.com/questions/18121902/using-ocmock-on-nsoperation-gives-bad-access
    LP_WaitBlock *errorDelay = [[LP_WaitBlock alloc] init:[lp.errorDelay doubleValue]];
    [connection start:lp];
    [connect stopMocking];
    [errorDelay.mock stopMocking];
    errorDelay.afterWait();

    [mockTransport verify];
}

- (void)testConnectionInitialCancelledFailureUsesCallback {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Handler called"];
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    connection.connectionToken = @"10101010101";
    connection.connectionId = @"10101";
    [connection changeState:disconnected toState:connected];
    
    SRLongPollingTransport* lp = [[ SRLongPollingTransport alloc] init];
    lp.pollingOperationQueue = nil;//set to nil to get around weird ARC OCMock bugs http://stackoverflow.com/questions/18121902/using-ocmock-on-nsoperation-gives-bad-access
    
    id connect = [SRMockNetwork mockHttpRequestOperationForClass:[AFHTTPRequestOperation class]
                                                      statusCode:@500
                                                           error:[[NSError alloc] initWithDomain:@"EXPECTED" code:NSURLErrorCancelled userInfo:nil]];
    
    id mockTransport = [OCMockObject partialMockForObject:lp];
    [[[mockTransport stub] andForwardToRealObject] poll:[OCMArg any] connectionData:[OCMArg any] completionHandler:[OCMArg isNotNil]];
    [[[mockTransport stub] andDo:^(NSInvocation * invocation) {
        //By Design LP will poll immediately when getting data.  We dont care about the second poll so lets just eat it here.
    }] poll:[OCMArg any] connectionData:[OCMArg any] completionHandler:[OCMArg isNil]];
    
    [lp start: connection connectionData:@"12345" completionHandler:^(id response, NSError *error){
        if (error) {
            [expectation fulfill];
        }
    }];
    [connect stopMocking];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

@end
