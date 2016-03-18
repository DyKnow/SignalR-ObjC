//
//  SREventSourceStreamReaderTests.m
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 2/23/16.
//  Copyright © 2016 DyKnow LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SREventSourceStreamReader.h"

@interface SREventSourceStreamReaderTests : XCTestCase

@end

@implementation SREventSourceStreamReaderTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testOutputStreamOpenCallsOpenedCallback {
    XCTestExpectation *opened = [self expectationWithDescription:@"opened"];
    
    id outputStream = [[NSOutputStream alloc] initToMemory];
    
    SREventSourceStreamReader *eventSource = [[SREventSourceStreamReader alloc] initWithStream:outputStream];
    eventSource.opened = ^() {
        NSLog(@"Opened");
        [opened fulfill];
    };
    eventSource.message = ^(SRServerSentEvent * sseEvent) {
        XCTFail(@"Expected Opened");
    };
    eventSource.closed = ^(NSError *exception) {
        XCTFail(@"Expected Opened");
    };
    [eventSource start];
    
    [[outputStream delegate] stream:outputStream handleEvent:NSStreamEventOpenCompleted];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testOutputStreamClosesWithoutErrorNeverOpensCallsClosedCallback {
    XCTestExpectation *closed = [self expectationWithDescription:@"closed"];
    
    id outputStream = [[NSOutputStream alloc] initToMemory];
    
    SREventSourceStreamReader *eventSource = [[SREventSourceStreamReader alloc] initWithStream:outputStream];
    eventSource.opened = ^() {
        XCTFail(@"Expected Closed");
    };
    eventSource.message = ^(SRServerSentEvent * sseEvent) {
        XCTFail(@"Expected Closed");
    };
    eventSource.closed = ^(NSError *exception) {
        XCTAssertNil(exception);
        [closed fulfill];
    };
    [eventSource start];
    
    //see the stream close without error
    [[outputStream delegate] stream:outputStream handleEvent:NSStreamEventEndEncountered];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testOutputStreamClosesWithoutErrorAfterOpeningCallsClosedCallback {
    XCTestExpectation *opened = [self expectationWithDescription:@"opened"];
    XCTestExpectation *closed = [self expectationWithDescription:@"closed"];

    id outputStream = [[NSOutputStream alloc] initToMemory];
    
    SREventSourceStreamReader *eventSource = [[SREventSourceStreamReader alloc] initWithStream:outputStream];
    eventSource.opened = ^() {
        [opened fulfill];
    };
    eventSource.message = ^(SRServerSentEvent * sseEvent) {
        XCTFail(@"Expected Opened or Closed");
    };
    eventSource.closed = ^(NSError *exception) {
        XCTAssertNil(exception);
        [closed fulfill];
    };
    [eventSource start];
    
    //see the stream open
    [[outputStream delegate] stream:outputStream handleEvent:NSStreamEventOpenCompleted];
    
    //see the stream close without error
    [[outputStream delegate] stream:outputStream handleEvent:NSStreamEventEndEncountered];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testOutputStreamClosesWithErrorAfterOpeningCallsClosedCallback {
    XCTestExpectation *opened = [self expectationWithDescription:@"opened"];
    XCTestExpectation *closed = [self expectationWithDescription:@"closed"];
    
    id outputStream = [[NSOutputStream alloc] initToMemory];
    
    SREventSourceStreamReader *eventSource = [[SREventSourceStreamReader alloc] initWithStream:outputStream];
    eventSource.opened = ^() {
        [opened fulfill];
    };
    eventSource.message = ^(SRServerSentEvent * sseEvent) {
        XCTFail(@"Expected Opened or Closed");
    };
    eventSource.closed = ^(NSError *exception) {
        XCTAssertNotNil(exception);
        [closed fulfill];
    };
    [eventSource start];
    
    //see the stream open
    [[outputStream delegate] stream:outputStream handleEvent:NSStreamEventOpenCompleted];
    
    //see the stream close without error
    id streamChanges = [OCMockObject niceMockForClass: [NSStream class]];
    [[[streamChanges stub] andReturn:[NSError errorWithDomain:@"yolo" code:0 userInfo:nil]] streamError];
    [[outputStream delegate] stream:streamChanges handleEvent:NSStreamEventEndEncountered];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testOutputStreamEndsWithErrorAfterOpeningCallsClosedCallback {
    XCTestExpectation *opened = [self expectationWithDescription:@"opened"];
    XCTestExpectation *closed = [self expectationWithDescription:@"closed"];
    
    id outputStream = [[NSOutputStream alloc] initToMemory];
    
    SREventSourceStreamReader *eventSource = [[SREventSourceStreamReader alloc] initWithStream:outputStream];
    eventSource.opened = ^() {
        [opened fulfill];
    };
    eventSource.message = ^(SRServerSentEvent * sseEvent) {
        XCTFail(@"Expected Opened or Closed");
    };
    eventSource.closed = ^(NSError *exception) {
        XCTAssertNotNil(exception);
        [closed fulfill];
    };
    [eventSource start];
    
    //see the stream open
    [[outputStream delegate] stream:outputStream handleEvent:NSStreamEventOpenCompleted];
    
    //see the stream close without error
    id streamChanges = [OCMockObject niceMockForClass: [NSStream class]];
    [[[streamChanges stub] andReturn:[NSError errorWithDomain:@"yolo" code:0 userInfo:nil]] streamError];
    [[outputStream delegate] stream:streamChanges handleEvent:NSStreamEventErrorOccurred];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

@end
