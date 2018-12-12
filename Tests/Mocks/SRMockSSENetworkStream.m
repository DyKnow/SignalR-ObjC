//
//  SRMockSSENetworkStream.m
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 3/15/16.
//  Copyright © 2016 DyKnow LLC. All rights reserved.
//

#import "SRMockSSENetworkStream.h"
#import "SRMockWaitBlockOperation.h"
#import <OCMock/OCMock.h>

@interface SRMockSSENetworkStream ()

@property (readwrite, nonatomic, strong) NSData* lastData;
@property (readwrite, nonatomic, strong) id dataDelegate;
@property (readwrite, nonatomic, strong) id mock;
@property (readwrite, nonatomic, strong) NSOutputStream* outputStream;
//only call this directly if you don't want to trigger the stream.opened callback
@property (readwrite, nonatomic, copy) void (^onSuccess)(AFHTTPRequestOperation *operation, id responseObject);
@property (readwrite, nonatomic, copy) void (^onFailure)(AFHTTPRequestOperation *operation, NSError *error);

@end

@implementation SRMockSSENetworkStream

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    __weak __typeof(&*self)weakSelf = self;
    
    _mock = [OCMockObject niceMockForClass:[AFHTTPRequestOperation class]];
    [[[_mock stub] andDo:^(NSInvocation *invocation) {
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        void (^successOut)(AFHTTPRequestOperation *operation, id responseObject);
        void (^failureOut)(AFHTTPRequestOperation *operation, NSError *error);
        [invocation getArgument:&successOut atIndex:2];
        [invocation getArgument:&failureOut atIndex:3];
        [strongSelf setOnSuccess:successOut];
        [strongSelf setOnFailure:failureOut];
    }] setCompletionBlockWithSuccess: [OCMArg any] failure: [OCMArg any]];
    // Here we stub the alloc class method **
    [[[_mock stub] andReturn:_mock] alloc];
    // And we stub initWithParam: passing the param we will pass to the method to test
    [[[_mock stub] andReturn:_mock] initWithRequest:[OCMArg any]];
    
    return self;
}

- (NSOutputStream *)stream {
    return self.outputStream;
}

- (void)prepareForOpeningResponse:(void (^)())then {
    return [self prepareForOpeningResponse:nil then:then];
}

- (void)prepareForOpeningResponse:(NSString *)response then:(void (^)())then {
    NSOutputStream* dataStream = [[NSOutputStream alloc] initToMemory];
    [[[self.mock stub] andReturn: dataStream] outputStream];
    _outputStream = dataStream;

    if (!response) {
        response = @"";
    }
    NSData* data = [response dataUsingEncoding:NSUTF8StringEncoding];
    
    id streamChanges = [OCMockObject niceMockForClass: [NSStream class]];
    [[[streamChanges stub] andReturn:data] propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    
    if (then) {
        then();
    }
    _dataDelegate = dataStream.delegate;
    _lastData = data;
    
    if (self.dataDelegate) {
        [self.dataDelegate stream:streamChanges handleEvent:NSStreamEventOpenCompleted];
    }
}


- (void)prepareForConnectTimeout:(NSInteger)timeout beforeCaptureTimeout:(void (^)(SRMockWaitBlockOperation *))beforeCaptureTimeout afterCaptureTimeout:(void (^)(SRMockWaitBlockOperation *))afterCaptureTimeout{
    //note: even though it's a connect timeout, we want an outputstream
    //so that we can verify it closes
    _outputStream = [[NSOutputStream alloc] initToMemory];
    [_outputStream open];
    [[[self.mock stub] andReturn: _outputStream] outputStream];

    SRMockWaitBlockOperation* transportConnectTimeout = [[SRMockWaitBlockOperation alloc] initWithWaitTime:10];
    if (beforeCaptureTimeout) {
        beforeCaptureTimeout(transportConnectTimeout);
    }
    [transportConnectTimeout stopMocking];
    if (afterCaptureTimeout) {
        afterCaptureTimeout(transportConnectTimeout);
    }
}

- (void)prepareForNextResponse:(NSString *)response then:(void (^)())then {
    NSMutableData* prior = [[NSMutableData alloc] initWithData: _lastData];
    NSData* data = [response dataUsingEncoding:NSUTF8StringEncoding];
    [prior appendData:data];
    id streamChanges = [OCMockObject niceMockForClass: [NSStream class]];
    [[[streamChanges stub] andReturn:prior] propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    
    if (then) {
        then();
    }
    
    if (self.dataDelegate) {
        [self.dataDelegate stream:streamChanges handleEvent:NSStreamEventHasSpaceAvailable];
    }
}

- (void)prepareForClose {
    if (self.onSuccess) {
        self.onSuccess(self.mock, nil);
    }
}

- (void)prepareForError:(NSError *)error {
    if (self.onFailure) {
        self.onFailure(self.mock, error);
    }
}

- (void)stopMocking {
    [_mock stopMocking];
}

- (void)dealloc {
    [self stopMocking];
}

@end
