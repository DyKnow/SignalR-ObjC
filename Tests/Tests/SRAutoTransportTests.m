//
//  SRAutoTransportTests.m
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 3/15/16.
//  Copyright © 2016 DyKnow LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <SocketRocket/SRWebSocket.h>
#import "SRConnection.h"
#import "SRConnectionInterface.h"
#import "SRAutoTransport.h"
#import "SRWebSocketTransport.h"
#import "SRServerSentEventsTransport.h"
#import "SRLongPollingTransport.h"
#import "SRMockClientTransport.h"
#import "SRMockWaitBlockOperation.h"
#import "SRMockWSNetworkStream.h"
#import "SRMockSSENetworkStream.h"
#import "SRMockNetwork.h"

@interface SRLongPollingTransport ()
@property (strong, nonatomic, readwrite) NSOperationQueue *pollingOperationQueue;
@end

@interface SRAutoTransport (UnitTest)

@property (strong, nonatomic, readonly) NSMutableArray *transports;

@end

@interface SRServerSentEventsTransport (UnitTests)

@property (strong, nonatomic, readwrite) NSOperationQueue *serverSentEventsOperationQueue;

@end

@interface SRAutoTransportTests : XCTestCase

@end

@implementation SRAutoTransportTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testAutoTransportAllowsForWS_SSE_LP {
    SRAutoTransport *autoTransport = [[SRAutoTransport alloc] init];
    XCTAssertEqual([[autoTransport transports] count], 3);
    XCTAssertTrue([[[[autoTransport transports] firstObject] name] isEqualToString:@"webSockets"]);
    XCTAssertTrue([[[autoTransport transports][1] name] isEqualToString:@"serverSentEvents"]);
    XCTAssertTrue([[[[autoTransport transports] lastObject] name] isEqualToString:@"longPolling"]);
}

- (void)testSlowToInitializeWebsocketCleansUpAndTriesNextTransport {
    XCTestExpectation *initialized = [self expectationWithDescription:@"Handler called"];

    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    SRWebSocketTransport *ws = [[SRWebSocketTransport alloc] init];
    id mockWSTrasport = [OCMockObject partialMockForObject:ws];
    [[[mockWSTrasport expect] andForwardToRealObject] start:[OCMArg any] connectionData:[OCMArg any] completionHandler:[OCMArg any]];
    SRServerSentEventsTransport *sse = [[SRServerSentEventsTransport alloc] init];
    [sse setServerSentEventsOperationQueue:nil];
    id mockSSETransport = [OCMockObject partialMockForObject:sse];
    [[[mockSSETransport expect] andForwardToRealObject] start:[OCMArg any] connectionData:[OCMArg any] completionHandler:[OCMArg any]];
    SRAutoTransport* autoTransport = [[SRAutoTransport alloc] initWithTransports:@[ws, sse]];
    
    id json = @{
        @"ConnectionId": @"10101",
        @"ConnectionToken": @"10101010101",
        @"DisconnectTimeout": @30,
        @"ProtocolVersion": @"1.3.0.0",
        @"TransportConnectTimeout": @10,
        @"TryWebSockets": @YES
    };
    [SRMockClientTransport negotiateForTransport:autoTransport statusCode:@200 json:json];
    
    connection.started = ^{
        [initialized fulfill];
    };
    
    SRMockWSNetworkStream *wsNetworkStream = [[SRMockWSNetworkStream alloc] init];
    [[[wsNetworkStream stream] expect] close];
    SRMockSSENetworkStream* sseNetworkStream = [[SRMockSSENetworkStream alloc] init];
    //Setup WS to get timed out so we fallback
    [wsNetworkStream prepareForConnectTimeout:10 beforeCaptureTimeout:^(SRMockWaitBlockOperation *transportConnectTimeout){
        //Start the connection now that the transport is setup to timeout
        [connection start:autoTransport];
    } afterCaptureTimeout:^(SRMockWaitBlockOperation *transportConnectTimeout){
        //Prepare for a successful connection with SSE
        [sseNetworkStream prepareForOpeningResponse:@"data: initialized\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}\n\n"  then:^{
            //Actually timeout the WS transport now
            transportConnectTimeout.afterWait();
        }];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
    [mockWSTrasport verify];
    [[wsNetworkStream stream] verify];
    [mockSSETransport verify];
    
    XCTAssert([[autoTransport name] isEqualToString:[sse name]]);
}

- (void)testSlowToInitializeServerSentEventsCleansUpAndTriesNextTransport {
    XCTestExpectation *initialized = [self expectationWithDescription:@"Handler called"];
    
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    
    SRServerSentEventsTransport *sse = [[SRServerSentEventsTransport alloc] init];
    [sse setServerSentEventsOperationQueue:nil];

    id mockSSETransport = [OCMockObject partialMockForObject:sse];
    [[[mockSSETransport expect] andForwardToRealObject] start:[OCMArg any] connectionData:[OCMArg any] completionHandler:[OCMArg any]];
    
    SRLongPollingTransport *lp = [[SRLongPollingTransport alloc] init];
    lp.pollingOperationQueue = nil;////set to nil to get around weird ARC OCMock bugs http://stackoverflow.com/questions/18121902/using-ocmock-on-nsoperation-gives-bad-access

    id mockLPTransport = [OCMockObject partialMockForObject:lp];
    [[[mockLPTransport expect] andForwardToRealObject] start:[OCMArg any] connectionData:[OCMArg any] completionHandler:[OCMArg any]];
    
    SRAutoTransport* autoTransport = [[SRAutoTransport alloc] initWithTransports:@[sse, lp]];
    
    id json = @{
                @"ConnectionId": @"10101",
                @"ConnectionToken": @"10101010101",
                @"DisconnectTimeout": @30,
                @"ProtocolVersion": @"1.3.0.0",
                @"TransportConnectTimeout": @10,
                @"TryWebSockets": @NO
                };
    [SRMockClientTransport negotiateForTransport:autoTransport statusCode:@200 json:json];
    __block id connect = nil;
    
    connection.started = ^{
        [initialized fulfill];//note, we wont fulfill this till we've fallen back to longPolling
        [connect stopMocking];//if we dont do this we create a tight loop as longpolling will
                    //instantly return more data
    };
    
    SRMockSSENetworkStream* sseNetworkStream = [[SRMockSSENetworkStream alloc] init];
    //cannot OCMock bridge free classes
    //    [[[sseNetworkStream stream] expect] close];
    

    //Setup SSE to get timed out so we fallback
    [sseNetworkStream prepareForConnectTimeout:10 beforeCaptureTimeout:^(SRMockWaitBlockOperation *transportConnectTimeout){
        //Start the connection and capture the performSelector blocks
        //for use later
        [connection start:autoTransport];
    } afterCaptureTimeout:^(SRMockWaitBlockOperation *transportConnectTimeout){
        //this is before the timeout has occurred, so last minute mock
        //the request
        connect = [SRMockNetwork mockHttpRequestOperationForClass:[AFHTTPRequestOperation class]
                                                          statusCode:@200
                                                      responseString:@"abcdefg"];
        transportConnectTimeout.afterWait();//calls the timeout method, afterWait is the block passed
        //at this point we should have fallen back to longPolling
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
    [mockSSETransport verify];
    XCTAssertEqual([[sseNetworkStream stream] streamStatus], NSStreamStatusClosed);
    
    XCTAssert([[autoTransport name] isEqualToString:[lp name]]);
}

@end
