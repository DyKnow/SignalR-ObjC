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

@interface SRHTTPRequestOperation : AFHTTPRequestOperation

typedef void (^AFURLConnectionOperationDidReceiveURLResponseBlock)(AFHTTPRequestOperation *operation, NSHTTPURLResponse *response);

- (void)setDidReceiveResponseBlock:(void (^)(AFHTTPRequestOperation *operation, NSHTTPURLResponse *response))block;
- (void)setCompletionBlockWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                              failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

@property (readwrite, nonatomic, strong) NSHTTPURLResponse *response;
@property (readwrite, nonatomic, copy) AFURLConnectionOperationDidReceiveURLResponseBlock urlResponseBlock;
@property (nonatomic, strong) NSOutputStream *outputStream;


@end

@interface SRServerSentEventsTransport ()
@property (strong, nonatomic, readwrite) NSOperationQueue *serverSentEventsOperationQueue;
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

- (void) testStartCallsTheCompletionHandlerAfterSuccess {
     XCTestExpectation *expectation = [self expectationWithDescription:@"Handler called"];
    
    __block void (^onGotResponse)(AFHTTPRequestOperation *operation, NSHTTPURLResponse *response);
    __block void (^onFailure)(NSError*);
    __block BOOL called;

    
    id mock = [OCMockObject niceMockForClass:[SRHTTPRequestOperation class]];
    [[[mock stub] andDo:^(NSInvocation *invocation) {
        void (^callbackOut)(AFHTTPRequestOperation *operation, NSHTTPURLResponse *response);
        [invocation getArgument: &callbackOut atIndex: 2];
        onGotResponse = callbackOut;
    }] setDidReceiveResponseBlock: [OCMArg any]];

    [[[mock stub] andDo:^(NSInvocation *invocation) {
        [invocation getArgument: &onFailure atIndex: 3];
    }] setCompletionBlockWithSuccess: [OCMArg any] failure: [OCMArg any]];
    
    
    // Here we stub the alloc class method **
    [[[mock stub] andReturn:mock] alloc];
    // And we stub initWithParam: passing the param we will pass to the method to test
    [[[mock stub] andReturn:mock] initWithRequest:[OCMArg any]];
    
    SRConnection* connection = [SRConnection alloc];
    [connection initWithURLString:@"http://localhost:0000"];
    __weak __typeof(&*mock)weakMock = mock;
    
    SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    sse.serverSentEventsOperationQueue = nil;//set to nil to get around weird ARC OCMock bugs
    
    [sse start: connection connectionData:@"12345" completionHandler:^(id response, NSError *error){
        [expectation fulfill];
    }];
    
    //Now we need to send it the data it expects
    NSOutputStream* dataStream = [[NSOutputStream alloc] initToMemory];
    [[[mock stub] andReturn: dataStream] outputStream];
     
    onGotResponse(mock, nil);
    
    [dataStream.delegate stream:dataStream handleEvent:NSStreamEventOpenCompleted];
    
    NSString* responseStr = @"data: {}\n";
    NSData* data = [responseStr dataUsingEncoding:NSUTF8StringEncoding];
//    [dataStream write: [data bytes] maxLength:[data length]];
    
    id streamChanges = [OCMockObject niceMockForClass: [NSStream class]];
    [[[streamChanges stub] andReturn:data] propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [dataStream.delegate stream:streamChanges handleEvent:NSStreamEventHasSpaceAvailable];

    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testConnectionErrorRetries {
    // This is an example of a functional test case.
    XCTAssert(NO, @"Yolo");
}

- (void)testLostConnectionAbortsAllConnections {
    // This is an example of a functional test case.
    XCTAssert(NO, @"Yolo");
}

@end
