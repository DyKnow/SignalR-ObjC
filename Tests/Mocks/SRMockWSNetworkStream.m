//
//  SRMockWSNetworkStream.m
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 3/15/16.
//  Copyright © 2016 DyKnow LLC. All rights reserved.
//

#import "SRMockWSNetworkStream.h"
#import <SocketRocket/SRWebSocket.h>
#import "SRMockWaitBlockOperation.h"

@interface SRMockWSNetworkStream ()

@property (readwrite, nonatomic, strong) id mockWebsocket;
@property (weak, nonatomic, readwrite) id dataDelegate;

@end

@implementation SRMockWSNetworkStream

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _mockWebsocket = [OCMockObject niceMockForClass:[SRWebSocket class]];
    [[[_mockWebsocket stub] andReturn:_mockWebsocket] alloc];
    __weak __typeof(&*self)weakSelf = self;
    [[[_mockWebsocket stub] andReturn:_mockWebsocket] initWithURLRequest:[OCMArg any]];
    [[[_mockWebsocket stub] andDo:^(NSInvocation *invocation) {
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        __unsafe_unretained id<SRWebSocketDelegate> delegate = nil;
        [invocation getArgument: &delegate atIndex: 2];
        [strongSelf setDataDelegate:delegate];
    }] setDelegate:[OCMArg any]];
    [[_mockWebsocket stub] open];
    
    return self;
}

- (OCMockObject *)stream {
    return self.mockWebsocket;
}

- (void)prepareForConnectTimeout:(NSInteger)timeout beforeCaptureTimeout:(void (^)(SRMockWaitBlockOperation *))beforeCaptureTimeout afterCaptureTimeout:(void (^)(SRMockWaitBlockOperation *))afterCaptureTimeout{
    SRMockWaitBlockOperation* transportConnectTimeout = [[SRMockWaitBlockOperation alloc] initWithWaitTime:10];
    if (beforeCaptureTimeout) {
        beforeCaptureTimeout(transportConnectTimeout);
    }
    [transportConnectTimeout stopMocking];
    if (afterCaptureTimeout) {
        afterCaptureTimeout(transportConnectTimeout);
    }
}

- (void)prepareForOpeningResponse:(void (^)())then; {
    return [self prepareForOpeningResponse:nil then:then];
}

- (void)prepareForOpeningResponse:(NSString *)response then:(void (^)())then; {
    
    if (!response) {
        response = @"";
    }
    
    if (self.dataDelegate && [self.dataDelegate respondsToSelector:@selector(webSocketDidOpen:)]) {
        [self.dataDelegate webSocketDidOpen:self.mockWebsocket];
    }
    if (self.dataDelegate && [self.dataDelegate respondsToSelector:@selector(webSocket:didReceiveMessage:)]) {
        [self.dataDelegate webSocket:self.mockWebsocket didReceiveMessage:response];
    }
}

- (void)prepareForNextResponse:(NSString *)response then:(void (^)())then; {
    if (!response) {
        response = @"";
    }
    if (self.dataDelegate && [self.dataDelegate respondsToSelector:@selector(webSocket:didReceiveMessage:)]) {
        [self.dataDelegate webSocket:self.mockWebsocket didReceiveMessage:response];
    }
}

- (void)prepareForError:(NSError *)error; {
    if (self.dataDelegate && [self.dataDelegate respondsToSelector:@selector(webSocket:didFailWithError:)]) {
        [self.dataDelegate webSocket:self.mockWebsocket didFailWithError:error];
    }
}

- (void)stopMocking; {
    [self.mockWebsocket stopMocking];
}

- (void)dealloc {
    [self stopMocking];
}

@end
