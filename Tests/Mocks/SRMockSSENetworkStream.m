//
//  SRMockSSENetworkStream.m
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 3/15/16.
//  Copyright © 2016 DyKnow LLC. All rights reserved.
//

#import "SRMockSSENetworkStream.h"
#import <OCMock/OCMock.h>

@interface SRMockSSENetworkStream ()

@property (readwrite, nonatomic, strong) NSData* lastData;
@property (readwrite, nonatomic, strong) id dataDelegate;
@property (readwrite, nonatomic, strong) id mock;
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

- (void)prepareForOpeningResponse:(void (^)())then {
    return [self prepareForOpeningResponse:nil then:then];
}

- (void)prepareForOpeningResponse:(NSString *)response then:(void (^)())then {
    NSOutputStream* dataStream = [[NSOutputStream alloc] initToMemory];
    [[[self.mock stub] andReturn: dataStream] outputStream];
    
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
