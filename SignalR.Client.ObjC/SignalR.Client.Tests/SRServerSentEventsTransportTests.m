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

@interface SRHTTPRequestOperation : AFHTTPRequestOperation

typedef void (^AFURLConnectionOperationDidReceiveURLResponseBlock)(AFHTTPRequestOperation *operation, NSHTTPURLResponse *response);

- (void)setDidReceiveResponseBlock:(void (^)(AFHTTPRequestOperation *operation, NSHTTPURLResponse *response))block;
- (void)setCompletionBlockWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                              failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

@property (readwrite, nonatomic, strong) NSHTTPURLResponse *response;
@property (readwrite, nonatomic, copy) AFURLConnectionOperationDidReceiveURLResponseBlock urlResponseBlock;
@property (nonatomic, strong) NSOutputStream *outputStream;


@end

@interface SRConnection (UnitTest)
@property (strong, nonatomic, readwrite) NSNumber * disconnectTimeout;
@end

@interface SRServerSentEventsTransport ()
@property (strong, nonatomic, readwrite) NSOperationQueue *serverSentEventsOperationQueue;
@property (assign) BOOL stop;
@end

@interface SSE_NetworkMock: NSObject
@property (readwrite, nonatomic, strong) id mock;
//only call this directly if you don't want to trigger the stream.opened callback
@property (readwrite, nonatomic, copy) void (^onGotResponse)(AFHTTPRequestOperation *operation, NSHTTPURLResponse *response);
@property (readwrite, nonatomic, copy) void (^onFailure)(AFHTTPRequestOperation *operation, NSError *error);
-(void) openingResponse: (NSString*) initialData;
-(void) message: (NSString*) messageStr;
@property (readwrite, nonatomic, strong) NSData* lastData;
@property (readwrite, nonatomic, strong) id dataDelegate;
@end

@implementation SSE_NetworkMock
- (id) init
{
    self = [super init];
    __weak __typeof(&*self)weakSelf = self;
    
    _mock = [OCMockObject niceMockForClass:[SRHTTPRequestOperation class]];
    [[[_mock stub] andDo:^(NSInvocation *invocation) {
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        void (^callbackOut)(AFHTTPRequestOperation *operation, NSHTTPURLResponse *response);
        [invocation getArgument: &callbackOut atIndex: 2];
        strongSelf.onGotResponse = callbackOut;
    }] setDidReceiveResponseBlock: [OCMArg any]];
    
    [[[_mock stub] andDo:^(NSInvocation *invocation) {
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        void (^failureOut)(AFHTTPRequestOperation *operation, NSError *error);
        [invocation getArgument: &failureOut atIndex: 3];
        strongSelf.onFailure = failureOut;
    }] setCompletionBlockWithSuccess: [OCMArg any] failure: [OCMArg any]];
    // Here we stub the alloc class method **
    [[[_mock stub] andReturn:_mock] alloc];
    // And we stub initWithParam: passing the param we will pass to the method to test
    [[[_mock stub] andReturn:_mock] initWithRequest:[OCMArg any]];
    
    return self;
}

-(void) openingResponse: (NSString*) initialData
{
    NSOutputStream* dataStream = [[NSOutputStream alloc] initToMemory];
    [[[self.mock stub] andReturn: dataStream] outputStream];
    self.onGotResponse(self.mock, nil);

    if (!initialData) {
        initialData = @"";
    }
    
    NSData* data = [initialData dataUsingEncoding:NSUTF8StringEncoding];
    id streamChanges = [OCMockObject niceMockForClass: [NSStream class]];
    [[[streamChanges stub] andReturn:data] propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [dataStream.delegate stream:streamChanges handleEvent:NSStreamEventOpenCompleted];
    _lastData = data;
    _dataDelegate = dataStream.delegate;
}

-(void) message: (NSString*) messageStr
{
    NSMutableData* data = [[NSMutableData alloc] initWithData: _lastData];
    [data appendData:[messageStr dataUsingEncoding:NSUTF8StringEncoding]];

    id streamChanges = [OCMockObject niceMockForClass: [NSStream class]];
    [[[streamChanges stub] andReturn:data] propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [_dataDelegate stream:streamChanges handleEvent:NSStreamEventHasSpaceAvailable];
    _lastData = data;
}

- (void)dealloc {
    [_mock stopMocking];
}

@end

@interface SSE_WaitBlock: NSObject
@property (readwrite, nonatomic, copy) void (^afterWait)();
@property (readwrite, nonatomic, assign) double waitTime;
@property (readwrite, nonatomic, strong) id mock;
@end

@implementation SSE_WaitBlock
- (id) init: (int)expectedWait{
    self = [super init];
    __weak __typeof(&*self)weakSelf = self;
    _afterWait = nil;
    _mock = [OCMockObject mockForClass:[NSBlockOperation class]];
    [[[[_mock stub] andReturn: _mock ] andDo:^(NSInvocation *invocation) {
         __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        __unsafe_unretained void (^successCallback)(AFHTTPRequestOperation *, NSHTTPURLResponse *) = nil;
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
    
    __block void (^onGotResponse)(AFHTTPRequestOperation *operation, NSHTTPURLResponse *response);
    __block void (^onFailure)(NSError*);
   
    id mock = [OCMockObject niceMockForClass:[SRHTTPRequestOperation class]];
    [[[mock stub] andDo:^(NSInvocation *invocation) {
        __unsafe_unretained void (^successCallback)(AFHTTPRequestOperation *, NSHTTPURLResponse *) = nil;
        [invocation getArgument: &successCallback atIndex: 2];
        onGotResponse = successCallback;
    }] setDidReceiveResponseBlock: [OCMArg any]];

    [[[mock stub] andDo:^(NSInvocation *invocation) {
        __unsafe_unretained void (^failureCallback)(NSError *) = nil;
        [invocation getArgument: &failureCallback atIndex: 3];
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

    __weak __typeof(&*mock)weakMock = mock;
    
    SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    sse.serverSentEventsOperationQueue = nil;//set to nil to get around weird ARC OCMock bugs http://stackoverflow.com/questions/18121902/using-ocmock-on-nsoperation-gives-bad-access
    
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
    id streamChanges = [OCMockObject niceMockForClass: [NSStream class]];
    [[[streamChanges stub] andReturn:data] propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [dataStream.delegate stream:streamChanges handleEvent:NSStreamEventHasSpaceAvailable];

    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testParsesInitialBuffer {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Handler called"];
    
    __block void (^onGotResponse)(AFHTTPRequestOperation *operation, NSHTTPURLResponse *response);
    __block void (^onFailure)(NSError*);
    
    id mock = [OCMockObject niceMockForClass:[SRHTTPRequestOperation class]];
    [[[mock stub] andDo:^(NSInvocation *invocation) {
        __unsafe_unretained void (^successCallback)(AFHTTPRequestOperation *, NSHTTPURLResponse *) = nil;
        [invocation getArgument: &successCallback atIndex: 2];
        onGotResponse = successCallback;
    }] setDidReceiveResponseBlock: [OCMArg any]];
    
    [[[mock stub] andDo:^(NSInvocation *invocation) {
        __unsafe_unretained void (^failureCallback)(NSError *) = nil;
        [invocation getArgument: &failureCallback atIndex: 3];
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

    __weak __typeof(&*mock)weakMock = mock;
    
    SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    sse.serverSentEventsOperationQueue = nil;//set to nil to get around weird ARC OCMock bugs http://stackoverflow.com/questions/18121902/using-ocmock-on-nsoperation-gives-bad-access
    
    [sse start: connection connectionData:@"12345" completionHandler:^(id response, NSError *error){
        [expectation fulfill];
    }];
    
    //Now we need to send it the data it expects
    NSOutputStream* dataStream = [[NSOutputStream alloc] initToMemory];
    [[[mock stub] andReturn: dataStream] outputStream];
    
    onGotResponse(mock, nil);
    
    
    NSString* responseStr = @"data: {}\n";
    NSData* data = [responseStr dataUsingEncoding:NSUTF8StringEncoding];
    
    id streamChanges = [OCMockObject niceMockForClass: [NSStream class]];
    [[[streamChanges stub] andReturn:data] propertyForKey:NSStreamDataWrittenToMemoryStreamKey];

    [dataStream.delegate stream:streamChanges handleEvent:NSStreamEventOpenCompleted];
    
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testIgnoresInitializedAndEmptyLinesWhenParsingMessages {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Handler called"];
    
    __block void (^onGotResponse)(AFHTTPRequestOperation *operation, NSHTTPURLResponse *response);
    __block void (^onFailure)(NSError*);
    
    id mock = [OCMockObject niceMockForClass:[SRHTTPRequestOperation class]];
    [[[mock stub] andDo:^(NSInvocation *invocation) {
        __unsafe_unretained void (^successCallback)(AFHTTPRequestOperation *, NSHTTPURLResponse *) = nil;
        [invocation getArgument: &successCallback atIndex: 2];
        onGotResponse = successCallback;
    }] setDidReceiveResponseBlock: [OCMArg any]];
    
    [[[mock stub] andDo:^(NSInvocation *invocation) {
        __unsafe_unretained void (^failureCallback)(NSError *) = nil;
        [invocation getArgument: &failureCallback atIndex: 3];
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

    __weak __typeof(&*mock)weakMock = mock;
    
    connection.received = ^(NSDictionary * data){
        if ([[data valueForKey:@"M"] isEqualToString:@"message"]
            && [[data valueForKey:@"H"] isEqualToString:@"hubname"]
            && [[data valueForKey:@"A"] isEqualToString:@"12345"]) {
            [expectation fulfill];
        }
    };
    
    SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    sse.serverSentEventsOperationQueue = nil;//set to nil to get around weird ARC OCMock bugs http://stackoverflow.com/questions/18121902/using-ocmock-on-nsoperation-gives-bad-access
    
    [sse start: connection connectionData:@"12345" completionHandler:^(id response, NSError *error){}];
    
    //Now we need to send it the data it expects
    NSOutputStream* dataStream = [[NSOutputStream alloc] initToMemory];
    [[[mock stub] andReturn: dataStream] outputStream];
    
    onGotResponse(mock, nil);
    
    
    NSString* responseStr = @"data: initialized\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}\n\n";
    NSData* data = [responseStr dataUsingEncoding:NSUTF8StringEncoding];
    
    id streamChanges = [OCMockObject niceMockForClass: [NSStream class]];
    [[[streamChanges stub] andReturn:data] propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    
    [dataStream.delegate stream:streamChanges handleEvent:NSStreamEventOpenCompleted];
    
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testConnectionInitialFailureUsesCallback {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Handler called"];
    
    __block void (^onGotResponse)(AFHTTPRequestOperation *operation, NSHTTPURLResponse *response);
    __block void (^onFailure)(AFHTTPRequestOperation *operation, NSError *error);
    
    id mock = [OCMockObject niceMockForClass:[SRHTTPRequestOperation class]];
    [[[mock stub] andDo:^(NSInvocation *invocation) {
        __unsafe_unretained void (^successCallback)(AFHTTPRequestOperation *, NSHTTPURLResponse *) = nil;
        [invocation getArgument: &successCallback atIndex: 2];
        onGotResponse = successCallback;
    }] setDidReceiveResponseBlock: [OCMArg any]];
    
    [[[mock stub] andDo:^(NSInvocation *invocation) {
        __unsafe_unretained void (^failureCallback)(AFHTTPRequestOperation *, NSError *) = nil;
        [invocation getArgument: &failureCallback atIndex: 3];
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

    __weak __typeof(&*mock)weakMock = mock;
    
    SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    sse.serverSentEventsOperationQueue = nil;//set to nil to get around weird ARC OCMock bugs http://stackoverflow.com/questions/18121902/using-ocmock-on-nsoperation-gives-bad-access
    
    [sse start: connection connectionData:@"12345" completionHandler:^(id response, NSError *error){
        if (error) {
            [expectation fulfill];
        }
    }];
    
    //Now we need to send it the data it expects
    NSOutputStream* dataStream = [[NSOutputStream alloc] initToMemory];
    [[[mock stub] andReturn: dataStream] outputStream];
    
    //set up test to verify we do not retry connection after failure
    id failmock = [OCMockObject mockForClass:[SRHTTPRequestOperation class]];
    [[failmock reject] alloc];
    
    onFailure(mock, [[NSError alloc] initWithDomain:@"EXPECTED" code:42 userInfo:nil]);
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testConnectionErrorRetries__RetriesAfterADelay__CommunicatesLifeCycleViaConnection {
    XCTestExpectation *initialized = [self expectationWithDescription:@"initialized"];
    SSE_NetworkMock* NetConnect = [[SSE_NetworkMock alloc] init];
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    __weak __typeof(&*connection)weakConnection = connection;
    __weak __typeof(&*self)weakSelf = self;
    __weak __typeof(&*NetConnect)weakNetConnect = NetConnect;
    connection.connectionToken = @"10101010101";
    connection.connectionId = @"10101";
    connection.disconnectTimeout = @30;
    connection.transportConnectTimeout =@10;
    [connection changeState:disconnected toState:connected];
 
    SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    sse.serverSentEventsOperationQueue = nil;//set to nil to get around weird ARC OCMock bugs http://stackoverflow.com/questions/18121902/using-ocmock-on-nsoperation-gives-bad-access
    
    [sse start: connection connectionData:@"12345" completionHandler:^(id response, NSError *error){
        [initialized fulfill];
    }];
    
    //gets the response and pulls down data successfully at start
    [NetConnect openingResponse: @"data: initialized\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}\n\n"];
    
    //have to pump messages to continue
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        } else {
            //and then something horrible happens
            __strong __typeof(&*weakSelf)strongSelf = weakSelf;
            __strong __typeof(&*weakConnection)strongConnection = weakConnection;
            __strong __typeof(&*weakNetConnect)strongNetConnect = weakNetConnect;
            
            //spoiler: we expect this to reconnect and for connection to communicate that out
            XCTestExpectation *expectation = [strongSelf expectationWithDescription:@"Retrying callback called"];
            XCTestExpectation *expectation2 = [strongSelf expectationWithDescription:@"Retry callback called"];
            strongConnection.reconnecting = ^(){
                [expectation fulfill];
            };
            strongConnection.reconnected = ^(){
                [expectation2 fulfill];
            };

            //do setup to simulate and verify the reconnect delay
            __block void (^reconnectAfterTimeoutCallback)();
            __block double reconnectDelay;
            id mock = [OCMockObject mockForClass:[NSBlockOperation class]];
            [[[[mock stub] andReturn: mock ] andDo:^(NSInvocation *invocation) {
                __unsafe_unretained void (^successCallback)() = nil;
                [invocation getArgument: &successCallback atIndex: 2];
                reconnectAfterTimeoutCallback = successCallback;
            }] blockOperationWithBlock: [OCMArg any]];
            [[[mock stub] andDo:^(NSInvocation *invocation) {
                double reconnectDelayOut = 0;
                [invocation getArgument: &reconnectDelayOut atIndex:4];
                reconnectDelay = reconnectDelayOut;
            }] performSelector:@selector(start) withObject:nil afterDelay: [[sse reconnectDelay] integerValue]];
            
            strongNetConnect.onFailure(strongNetConnect.mock, [[NSError alloc]initWithDomain:@"EXPECTED" code:42 userInfo:nil]);
            [mock stopMocking];//dont want to accidentally get other blocks
            XCTAssertEqual(2, reconnectDelay, "Unexpected reconnect delay");
            
            //we will be calling open again, so lets recapture the data to verify
            SSE_NetworkMock* NetReconnect = [[SSE_NetworkMock alloc]init];
            
            reconnectAfterTimeoutCallback();//simulating retry timeout
            [NetReconnect openingResponse:nil];
            //todo: verify request url was reconnect not connect, but then you have to sovle ARC
            [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
                if (error){
                    NSLog(@"Sub-Timeout Error: %@", error);
                }
            }];
        }
    }];
}

- (void)testLostConnectionAbortsAllConnectionsAndReconnects {
    // happens when healthy connection misses too many heartbeats
    XCTestExpectation *initialized = [self expectationWithDescription:@"initialized"];
    SSE_NetworkMock* NetConnect = [[SSE_NetworkMock alloc] init];
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    __weak __typeof(&*self)weakSelf = self;
    __weak __typeof(&*connection)weakConnection = connection;
    __weak __typeof(&*NetConnect)weakNetConnect = NetConnect;
    connection.connectionToken = @"10101010101";
    connection.connectionId = @"10101";
    connection.disconnectTimeout = @30;
    connection.transportConnectTimeout =@10;
    [connection changeState:disconnected toState:connected];
    
    SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    id queueMock = [OCMockObject niceMockForClass:[NSOperationQueue class]];
    [[queueMock expect] cancelAllOperations];
    sse.serverSentEventsOperationQueue = queueMock;
    [sse start: connection connectionData:@"12345" completionHandler:^(id response, NSError *error){
        [initialized fulfill];
    }];
    //gets the response and pulls down data successfully at start
    [NetConnect openingResponse: @"data: initialized\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}\n\n"];
     
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error); return;
        }
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        __strong __typeof(&*weakNetConnect)strongNetConnect = weakNetConnect;

        //and then we lose connection with the server
        //spoiler: we expect this to reconnect and for connection to communicate that out
        XCTestExpectation *expectation = [strongSelf expectationWithDescription:@"Retrying callback called"];
        XCTestExpectation *expectation2 = [strongSelf expectationWithDescription:@"Retry callback called"];
        strongConnection.reconnecting = ^(){
            [expectation fulfill];
        };
        strongConnection.reconnected = ^(){
            [expectation2 fulfill];
        };
        
        //do setup to simulate and verify the reconnect delay
        SSE_WaitBlock* reconnectDelay = [[SSE_WaitBlock alloc] init:[[sse reconnectDelay] doubleValue]];
        
        //loses connection immediately, everything gets cleared out, but we
        //do not reconnect till later
        [sse lostConnection:connection];
        [queueMock verify];//clears out the queue after the timeout

        //we will be calling open again, so lets recapture the data to verify
        SSE_NetworkMock* NetReconnect = [[SSE_NetworkMock alloc]init];
        NSError *cancelledError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];//when the operation is cancelled, it yields the NSURLErrorCancelled error. From https://github.com/AFNetworking/AFNetworking/blob/c9bbbeb9cae6aeceef5353fd273fc48329009c3f/AFNetworking/AFURLConnectionOperation.m#L502
        strongNetConnect.onFailure(strongNetConnect.mock, cancelledError);
        [reconnectDelay.mock stopMocking];//dont want to accidentally get other blocks
        reconnectDelay.afterWait();
        XCTAssertEqual(2, reconnectDelay.waitTime, "Unexpected reconnect delay");
        
        [NetReconnect openingResponse:nil];
        [strongSelf waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
            if (error){
                NSLog(@"Sub-Timeout Error: %@", error);
            }
        }];
    }];
}

- (void)testDisconnectsOnReconnectTimeout {
    XCTestExpectation *initialized = [self expectationWithDescription:@"initialized"];
    SSE_NetworkMock* NetConnect = [[SSE_NetworkMock alloc] init];
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    __weak __typeof(&*self)weakSelf = self;
    __weak __typeof(&*connection)weakConnection = connection;
    __weak __typeof(&*NetConnect)weakNetConnect = NetConnect;
    connection.connectionToken =
    connection.connectionId = @"10101";
    connection.disconnectTimeout = @30;
    connection.transportConnectTimeout =@10;
    
    __block SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    sse.serverSentEventsOperationQueue = nil;//set to nil to avoid ARC error http://stackoverflow.com/questions/18121902/using-ocmock-on-nsoperation-gives-bad-access
    
    id pmock = [OCMockObject partialMockForObject: sse];
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
        [initialized fulfill];
    };
    
    [connection start:sse];
    
    //gets the response and pulls down data successfully at start
    [NetConnect openingResponse: @"data: initialized\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}\n\n"];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error); return;
        }
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        __strong __typeof(&*weakNetConnect)strongNetConnect = weakNetConnect;
        
        //trigger an error to see 
        //spoiler: we expect this to reconnect and for connection to communicate that out
        XCTestExpectation *expectation = [strongSelf expectationWithDescription:@"Retrying callback called"];
        XCTestExpectation *expectation2 = [strongSelf expectationWithDescription:@"disconnected callback called"];
        strongConnection.reconnecting = ^(){
            [expectation fulfill];
        };
        strongConnection.reconnected = ^(){
            XCTAssert(NO, @"unexpected change!");
        };
        
        strongConnection.closed = ^(){
            [expectation2 fulfill];
        };
        
        //do setup to simulate and verify the reconnect delay
        SSE_WaitBlock* reconnectBlock = [[SSE_WaitBlock alloc]init:[[sse reconnectDelay] doubleValue]];
        NSError *cancelledError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
        strongNetConnect.onFailure(strongNetConnect.mock, cancelledError);
        [reconnectBlock.mock stopMocking];//dont want to accidentally get other blocks
        
        //we will be calling open again, so lets recapture the data to verify
        SSE_NetworkMock* NetReconnect = [[SSE_NetworkMock alloc]init];
        //prep to catch the reconnect timeout
        SSE_WaitBlock* reconnectTimeoutBlock = [[SSE_WaitBlock alloc] init:[connection.disconnectTimeout doubleValue]];

        //retry has waited now,
        reconnectBlock.afterWait();
        XCTAssertEqual([connection.disconnectTimeout doubleValue], reconnectTimeoutBlock.waitTime, @"got timeout value from an unexpected place - check to be sure we are pulling from the connection");
        
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
    }];
}

- (void)xtestHandlesDisconnectMessageFromConnection {
    XCTAssert(NO, @"not implemented - need to determine support. 2.0.2 sends the D:1 disconenct message but latest does not");
}

- (void)testHandlesExtraEmptyLinesWhenParsingMessages {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Handler called"];
    
    __block void (^onGotResponse)(AFHTTPRequestOperation *operation, NSHTTPURLResponse *response);
    __block void (^onFailure)(NSError*);
    
    id mock = [OCMockObject niceMockForClass:[SRHTTPRequestOperation class]];
    [[[mock stub] andDo:^(NSInvocation *invocation) {
        __unsafe_unretained void (^successCallback)(AFHTTPRequestOperation *, NSHTTPURLResponse *) = nil;
        [invocation getArgument: &successCallback atIndex: 2];
        onGotResponse = successCallback;
    }] setDidReceiveResponseBlock: [OCMArg any]];
    
    [[[mock stub] andDo:^(NSInvocation *invocation) {
        __unsafe_unretained void (^failureCallback)(NSError *) = nil;
        [invocation getArgument: &failureCallback atIndex: 3];
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

    __weak __typeof(&*mock)weakMock = mock;
    
    connection.received = ^(NSString * data){
        if (data) {
            [expectation fulfill];
        }
    };
    
    SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    sse.serverSentEventsOperationQueue = nil;//set to nil to get around weird ARC OCMock bugs http://stackoverflow.com/questions/18121902/using-ocmock-on-nsoperation-gives-bad-access
    
    [sse start: connection connectionData:@"12345" completionHandler:^(id response, NSError *error){}];
    
    //Now we need to send it the data it expects
    NSOutputStream* dataStream = [[NSOutputStream alloc] initToMemory];
    [[[mock stub] andReturn: dataStream] outputStream];
    
    onGotResponse(mock, nil);
    
    
    NSString* responseStr = @"data: initialized\n\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}\n\n";
    NSData* data = [responseStr dataUsingEncoding:NSUTF8StringEncoding];
    
    id streamChanges = [OCMockObject niceMockForClass: [NSStream class]];
    [[[streamChanges stub] andReturn:data] propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    
    [dataStream.delegate stream:streamChanges handleEvent:NSStreamEventOpenCompleted];
    
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testHandlesNewLinesSpreadOutOverReads {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Handler called"];
    
    __block void (^onGotResponse)(AFHTTPRequestOperation *operation, NSHTTPURLResponse *response);
    __block void (^onFailure)(NSError*);
    
    id mock = [OCMockObject niceMockForClass:[SRHTTPRequestOperation class]];
    [[[mock stub] andDo:^(NSInvocation *invocation) {
        __unsafe_unretained void (^successCallback)(AFHTTPRequestOperation *, NSHTTPURLResponse *) = nil;
        [invocation getArgument: &successCallback atIndex: 2];
        onGotResponse = successCallback;
    }] setDidReceiveResponseBlock: [OCMArg any]];
    
    [[[mock stub] andDo:^(NSInvocation *invocation) {
        __unsafe_unretained void (^failureCallback)(NSError *) = nil;
        [invocation getArgument: &failureCallback atIndex: 3];
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

    __weak __typeof(&*mock)weakMock = mock;
    
    connection.received = ^(NSDictionary * data){
        if ([[data valueForKey:@"M"] isEqualToString:@"message"]
            && [[data valueForKey:@"H"] isEqualToString:@"hubname"]
            && [[data valueForKey:@"A"] isEqualToString:@"12345"]) {
            [expectation fulfill];
        }
    };

    
    SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    sse.serverSentEventsOperationQueue = nil;//set to nil to get around weird ARC OCMock bugs http://stackoverflow.com/questions/18121902/using-ocmock-on-nsoperation-gives-bad-access
    
    [sse start: connection connectionData:@"12345" completionHandler:^(id response, NSError *error){}];
    
    //Now we need to send it the data it expects
    NSOutputStream* dataStream = [[NSOutputStream alloc] initToMemory];
    [[[mock stub] andReturn: dataStream] outputStream];
    
    onGotResponse(mock, nil);
    
    
    NSString* responseStr = @"data: initialized\n\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}";
    NSMutableData* data1 = [ responseStr dataUsingEncoding:NSUTF8StringEncoding];
    
    id streamChanges = [OCMockObject niceMockForClass: [NSStream class]];
    [[[streamChanges stub] andReturn:data1] propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    
    [dataStream.delegate stream:streamChanges handleEvent:NSStreamEventOpenCompleted];
    
    //currently, SSE uses the same stream over and over and expects that same stream
    //to have all previous bytes in it. That said bc this is async, to actually test
    //the differences, we will create a separate stream
    NSMutableData* data2 = [[NSMutableData alloc] initWithData: data1];
    NSString* responseStrEnd = @"\n";
    [data2 appendData:[responseStrEnd dataUsingEncoding:NSUTF8StringEncoding]];
    id moreStreamChanges = [OCMockObject niceMockForClass: [NSStream class]];
    [[[moreStreamChanges stub] andReturn:data2] propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    
    [dataStream.delegate stream:moreStreamChanges handleEvent:NSStreamEventHasSpaceAvailable];
    
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
    
    id pmock = [OCMockObject partialMockForObject: sse];
    [[[pmock stub] andDo:^(NSInvocation *invocation) {
        void (^callbackOut)(SRNegotiationResponse * response, NSError *error);
        __unsafe_unretained void (^successCallback)(SRNegotiationResponse *, NSError *) = nil;
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
    
    SSE_WaitBlock* transportConnectTimeout = [[SSE_WaitBlock alloc]init: 10];
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
    SSE_NetworkMock* NetConnect = [[SSE_NetworkMock alloc] init];
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    connection.transportConnectTimeout =@10;
    
    SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    sse.serverSentEventsOperationQueue = nil;//set to nil to avoid ARC error http://stackoverflow.com/questions/18121902/using-ocmock-on-nsoperation-gives-bad-access
    
    id pmock = [OCMockObject partialMockForObject: sse];
    [[[pmock stub] andDo:^(NSInvocation *invocation) {
        void (^ callbackOut)(SRNegotiationResponse * response, NSError *error);
        __unsafe_unretained void (^successCallback)(SRNegotiationResponse *, NSError *) = nil;
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
    [connection start:sse];
    
    [NetConnect openingResponse: @"data: initialized\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}\n\n"];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
        XCTAssert(startCount == 1, @"expected exactly one started callback");
    }];
}

- (void)xtestPingIntervalStopsTheConnectionOn401s {
    XCTestExpectation *initialized = [self expectationWithDescription:@"initialized"];
    SSE_NetworkMock* NetConnect = [[SSE_NetworkMock alloc] init];
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    
    SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    sse.serverSentEventsOperationQueue = nil;//set to nil to avoid ARC error http://stackoverflow.com/questions/18121902/using-ocmock-on-nsoperation-gives-bad-access
    
    id pmock = [OCMockObject partialMockForObject: sse];
    [[[pmock stub] andDo:^(NSInvocation *invocation) {
        void (^ callbackOut)(SRNegotiationResponse * response, NSError *error);
        __unsafe_unretained void (^successCallback)(SRNegotiationResponse *, NSError *) = nil;
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
    
    [connection start:sse];
    
    [NetConnect openingResponse: @"data: initialized\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}\n\n"];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)xtestPingIntervalStopsTheConnectionOn403s {
    XCTestExpectation *initialized = [self expectationWithDescription:@"initialized"];
    SSE_NetworkMock* NetConnect = [[SSE_NetworkMock alloc] init];
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    
    SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    sse.serverSentEventsOperationQueue = nil;//set to nil to avoid ARC error http://stackoverflow.com/questions/18121902/using-ocmock-on-nsoperation-gives-bad-access
    
    id pmock = [OCMockObject partialMockForObject: sse];
    [[[pmock stub] andDo:^(NSInvocation *invocation) {
        void (^ callbackOut)(SRNegotiationResponse * response, NSError *error);
        __unsafe_unretained void (^successCallback)(SRNegotiationResponse *, NSError *) = nil;
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
    
    [connection start:sse];
    
    [NetConnect openingResponse: @"data: initialized\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}\n\n"];
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
    SSE_NetworkMock* NetConnect = [[SSE_NetworkMock alloc] init];
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    __weak __typeof(&*self)weakSelf = self;
    __weak __typeof(&*connection)weakConnection = connection;
    __weak __typeof(&*NetConnect)weakNetConnect = NetConnect;
    
    __block SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    sse.serverSentEventsOperationQueue = nil;//set to nil to avoid ARC error http://stackoverflow.com/questions/18121902/using-ocmock-on-nsoperation-gives-bad-access
    
    id pmock = [OCMockObject partialMockForObject: sse];
    [[[pmock stub] andDo:^(NSInvocation *invocation) {
        void (^ callbackOut)(SRNegotiationResponse * response, NSError *error);
        __unsafe_unretained void (^successCallback)(SRNegotiationResponse *, NSError *) = nil;
        [invocation getArgument: &successCallback atIndex: 4];
        callbackOut = successCallback;
        callbackOut([[SRNegotiationResponse alloc ]
                     initWithDictionary:@{
                        @"ConnectionId": @"10101",
                        @"ConnectionToken": @"10101010101",
                        @"DisconnectTimeout": @30,
                        @"ProtocolVersion": @"1.3.0.0",
                        @"TransportConnectTimeout": @10
                        }], nil);
    }] negotiate:[OCMArg any] connectionData:[OCMArg any] completionHandler:[OCMArg any]];
    
    
    connection.started = ^{
        [initialized fulfill];
    };
    
    [connection start:sse];
    
    //gets the response and pulls down data successfully at start
    [NetConnect openingResponse: @"data: initialized\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message\", \"A\": \"12345\"}]}\n\n"];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error); return;
        }
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        __strong __typeof(&*weakNetConnect)strongNetConnect = weakNetConnect;
        
        //trigger an error to see
        //spoiler: we expect this to fail
        XCTestExpectation *expectation2 = [strongSelf expectationWithDescription:@"disconnected callback called"];

        strongConnection.reconnected = ^(){
            XCTAssert(NO, @"unexpected change!");
        };
        
        strongConnection.closed = ^(){
            [expectation2 fulfill];
        };
        
        //do setup to simulate and verify the reconnect delay
        SSE_WaitBlock* reconnectBlock = [[SSE_WaitBlock alloc]init:[[sse reconnectDelay] doubleValue]];
        NSError *cancelledError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
        strongNetConnect.onFailure(strongNetConnect.mock, cancelledError);
        [reconnectBlock.mock stopMocking];//dont want to accidentally get other blocks
        
        //we will be calling open again, so lets recapture the data to verify
        SSE_NetworkMock* NetReconnect = [[SSE_NetworkMock alloc]init];
        //prep to catch the reconnect timeout
        SSE_WaitBlock* reconnectTimeoutBlock = [[SSE_WaitBlock alloc]init: [connection.disconnectTimeout doubleValue]];
        
        //retry has waited now,
        reconnectBlock.afterWait();
        XCTAssertEqual([connection.disconnectTimeout doubleValue], reconnectTimeoutBlock.waitTime, @"got timeout value from an unexpected place - check to be sure we are pulling from the connection");
     
        //connection timed out without succeeding
        reconnectTimeoutBlock.afterWait();
        
        [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
            if (error){
                NSLog(@"Sub-Timeout Error: %@", error);
            }
            sse = nil;
        }];
    }];
}

- (void)testConnectionCanBeStoppedDuringTransportStart {
    XCTestExpectation *initialized = [self expectationWithDescription:@"initialized"];
    SSE_NetworkMock* NetConnect = [[SSE_NetworkMock alloc] init];
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    __weak __typeof(&*self)weakSelf = self;
    __weak __typeof(&*connection)weakConnection = connection;
    __weak __typeof(&*NetConnect)weakNetConnect = NetConnect;
    
    __block SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    sse.serverSentEventsOperationQueue = nil;//set to nil to avoid ARC error http://stackoverflow.com/questions/18121902/using-ocmock-on-nsoperation-gives-bad-access
    
    id pmock = [OCMockObject partialMockForObject: sse];
    [[[pmock stub] andDo:^(NSInvocation *invocation) {
        void (^ callbackOut)(SRNegotiationResponse * response, NSError *error);
        __unsafe_unretained void (^successCallback)(SRNegotiationResponse *, NSError *) = nil;
        [invocation getArgument: &successCallback atIndex: 4];
        callbackOut = successCallback;
        callbackOut([[SRNegotiationResponse alloc ]
                     initWithDictionary:@{
                                          @"ConnectionId": @"10101",
                                          @"ConnectionToken": @"10101010101",
                                          @"DisconnectTimeout": @30,
                                          @"ProtocolVersion": @"1.3.0.0",
                                          @"TransportConnectTimeout": @10
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
    
    [connection start:sse];
    
    //gets the response but has not completed intialize
    [NetConnect openingResponse: @""];
    [connection stop];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error); return;
        }
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        XCTAssertEqual(strongConnection.state, disconnected, @"Connection was not disconnected");
        XCTAssertEqual(strongConnection.transport, nil, @"Transport was not cleared after stop");
    }];
}

- (void)testConnectionCanBeStoppedPriorToTransportStart {
    XCTestExpectation *initialized = [self expectationWithDescription:@"initialized"];
    SSE_NetworkMock* NetConnect = [[SSE_NetworkMock alloc] init];
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    __weak __typeof(&*self)weakSelf = self;
    __weak __typeof(&*connection)weakConnection = connection;
    __weak __typeof(&*NetConnect)weakNetConnect = NetConnect;
    
    __block SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
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
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        XCTAssertEqual(strongConnection.state, disconnected, @"Connection was not disconnected");
        XCTAssertEqual(strongConnection.transport, nil, @"Transport was not cleared after stop");
    }];
}

- (void)testTransportCanSendAndReceiveMessagesOnConnect {
    XCTestExpectation *initialized = [self expectationWithDescription:@"initialized"];
    SSE_NetworkMock* NetConnect = [[SSE_NetworkMock alloc] init];
    SRConnection* connection = [[SRConnection alloc] initWithURLString:@"http://localhost:0000"];
    __weak __typeof(&*self)weakSelf = self;
    __weak __typeof(&*connection)weakConnection = connection;
    __weak __typeof(&*NetConnect)weakNetConnect = NetConnect;
    
    __block SRServerSentEventsTransport* sse = [[SRServerSentEventsTransport alloc] init];
    sse.serverSentEventsOperationQueue = nil;//set to nil to avoid ARC error
    
    id pmock = [OCMockObject partialMockForObject: sse];
    [[[pmock stub] andDo:^(NSInvocation *invocation) {
        __unsafe_unretained void (^ callbackOut)(SRNegotiationResponse * response, NSError *error);
        [invocation getArgument: &callbackOut atIndex: 4];
        callbackOut([[SRNegotiationResponse alloc ]
                     initWithDictionary:@{
                                          @"ConnectionId": @"10101",
                                          @"ConnectionToken": @"10101010101",
                                          @"DisconnectTimeout": @30,
                                          @"ProtocolVersion": @"1.3.0.0",
                                          @"TransportConnectTimeout": @10
                                          }], nil);
    }] negotiate:[OCMArg any] connectionData:[OCMArg any] completionHandler:[OCMArg any]];
    [[[pmock stub] andDo:^(NSInvocation * invocation) {
        __unsafe_unretained void (^ callbackOut)(id * response, NSError *error);
        [invocation getArgument: &callbackOut atIndex: 5];
        callbackOut(nil, nil);//SSE just falls back to httpbase, just verify we are allowed through
    }] send:[OCMArg any]  data:[OCMArg any] connectionData:[OCMArg any] completionHandler:[OCMArg any]];
    
    __block NSMutableArray* values = [[NSMutableArray alloc] init];
    
    connection.started = ^(){
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        [strongConnection send:@"test" completionHandler:^(id response, NSError *error) {
            //after sending receive two more
            __strong __typeof(&*weakNetConnect)strongNetConnect = weakNetConnect;
            [strongNetConnect message:@"data: {\"M\":[{\"H\":\"hubname\", \"M\":\"message3\", \"A\": \"12345\"}]}\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message4\", \"A\": \"12345\"}]}\n\n"];
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
    
    [connection start:sse];
    
    [NetConnect openingResponse: @"data: initialized\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message1\", \"A\": \"12345\"}]}\n\ndata: {\"M\":[{\"H\":\"hubname\", \"M\":\"message2\", \"A\": \"12345\"}]}\n\n"];
    
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
    
    id pmock = [OCMockObject partialMockForObject: sse];
    [[[pmock stub] andDo:^(NSInvocation *invocation) {
        __unsafe_unretained void (^ callbackOut)(SRNegotiationResponse * response, NSError *error);
        [invocation getArgument: &callbackOut atIndex: 4];
        callbackOut([[SRNegotiationResponse alloc ]
                     initWithDictionary:@{
                                          @"ConnectionId": @"10101",
                                          @"ConnectionToken": @"10101010101",
                                          @"DisconnectTimeout": @30,
                                          @"ProtocolVersion": @"2.0.0.0",
                                          @"TransportConnectTimeout": @10
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

@end
