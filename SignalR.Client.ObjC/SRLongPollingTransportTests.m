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
//
//@interface SRHTTPRequestOperation : AFHTTPRequestOperation
//
//typedef void (^AFURLConnectionOperationDidReceiveURLResponseBlock)(AFHTTPRequestOperation *operation, NSHTTPURLResponse *response);
//
//- (void)setDidReceiveResponseBlock:(void (^)(AFHTTPRequestOperation *operation, NSHTTPURLResponse *response))block;
//- (void)setCompletionBlockWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
//                              failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
//
//@property (readwrite, nonatomic, strong) NSHTTPURLResponse *response;
//@property (readwrite, nonatomic, copy) AFURLConnectionOperationDidReceiveURLResponseBlock urlResponseBlock;
//@property (nonatomic, strong) NSOutputStream *outputStream;
//
//@end


@interface SRLongPollingTransport ()
@property (strong, nonatomic, readwrite) NSOperationQueue *pollingOperationQueue;
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

    __block void (^onGotResponse)(AFHTTPRequestOperation *operation, NSHTTPURLResponse *response);
    __block void (^onFailure)(NSError*);
    id mock = [OCMockObject niceMockForClass:[AFHTTPRequestOperation class]];
    [[[mock stub] andDo:^(NSInvocation *invocation) {
        __unsafe_unretained void (^successCallback)(AFHTTPRequestOperation *, NSHTTPURLResponse *) = nil;
        __unsafe_unretained void (^failureCallback)(NSError *) = nil;
        [invocation getArgument: &successCallback atIndex: 2];
        [invocation getArgument: &failureCallback atIndex: 3];
        onGotResponse = successCallback;
        onFailure = failureCallback;
    }] setCompletionBlockWithSuccess: [OCMArg any] failure: [OCMArg any]];
    
    // Here we stub the alloc class method **
    [[[mock stub] andReturn:mock] alloc];
    // And we stub initWithParam: passing the param we will pass to the method to test
    [[[mock stub] andReturn:mock] initWithRequest:[OCMArg any]];
    
    SRConnection* connection = [SRConnection alloc];
    [connection initWithURLString:@"http://localhost:0000"];
    connection.connectionToken = @"10101010101";
    connection.connectionId = @"10101";
    [connection changeState:disconnected toState:connected];
    
    SRLongPollingTransport* lp = [[ SRLongPollingTransport alloc] init];
    lp.pollingOperationQueue = nil;//set to nil to get around weird ARC OCMock bugs http://stackoverflow.com/questions/18121902/using-ocmock-on-nsoperation-gives-bad-access

    [lp start: connection connectionData:@"12345" completionHandler:^(id response, NSError *error){
        [expectation fulfill];
    }];
    
    
    //Now we need to send it the data it expects
    NSOutputStream* dataStream = [[NSOutputStream alloc] initToMemory];
    [[[mock stub] andReturn: dataStream] outputStream];
    
    onGotResponse(mock, nil);
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];

//    
//    NSString* responseStr = @'{"C":"d-84EE207C-B,0|BXW,0|BVk,0|BXX,1|BXY,0","S":1,"M":[]}';
//    NSData* data = [responseStr dataUsingEncoding:NSUTF8StringEncoding];
//    //    [dataStream write: [data bytes] maxLength:[data length]];
//    
//    id streamChanges = [OCMockObject niceMockForClass: [NSStream class]];
//    [[[streamChanges stub] andReturn:data] propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
//    [dataStream.delegate stream:streamChanges handleEvent:NSStreamEventHasSpaceAvailable];
    
    

}

- (void)testAbortFromErrorDoesNotRetry {
    //if you listen for errors and abort, we should not create another
    //poll/connect/reconnect request
    XCTAssert(NO, @"not implemented");
}

- (void)testLostConnectionAbortsAllConnections {
    // This is an example of a functional test case.
    XCTAssert(NO, @"not implemented");
}

- (void)testSlowConnectionGetsCommunicated {
    // This is an example of a functional test case.
    XCTAssert(NO, @"not implemented");
}

- (void)testTimeoutOnConnectionWillRetry {
    // This is an example of a functional test case.
    XCTAssert(NO, @"not implemented");
}

- (void)testErrorOnConnectionWillRetry {
    // This is an example of a functional test case.
    XCTAssert(NO, @"not implemented");
}

- (void)testFailureOnStartMakesItToTheDelegate {
    // This is an example of a functional test case.
    XCTAssert(NO, @"not implemented");
}
@end
