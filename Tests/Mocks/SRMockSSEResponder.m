//
//  SRMockSSEResponder.m
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 7/7/16.
//  Copyright © 2016 DyKnow LLC. All rights reserved.
//

#import "SRMockSSEResponder.h"

typedef void (^SRMockSSEResponderBeforeStartBlock)(void);
typedef void (^SRMockSSEResponderAfterStartBlock)(void);
typedef void (^SRMockSSEResponderBeforeDataBlock)(NSData * _Nonnull data);
typedef void (^SRMockSSEResponderAfterDataBlock)(NSData * _Nonnull data);
typedef void (^SRMockSSEResponderBeforeEndBlock)(NSError * _Nullable error);
typedef NSError * (^SRMockSSEResponderFailWithErrorBlock)(void);
typedef void (^SRMockSSEResponderAfterEndBlock)(NSError * _Nullable error);

@interface SRMockSSEResponder ()

@property (readwrite, nonatomic) NSArray<NSData *> * bodyChunks;

/*! The HTTP status code that the instance responds with. */
@property (readonly, nonatomic) NSInteger statusCode;

- (instancetype)init NS_UNAVAILABLE;

/*! Whether the responder is currently responding to a request. */
@property (nonatomic, getter = isResponding) BOOL responding;

@property (readwrite, nonatomic, copy) SRMockSSEResponderBeforeStartBlock beforeStart;
@property (readwrite, nonatomic, copy) SRMockSSEResponderAfterStartBlock afterStart;
@property (readwrite, nonatomic, copy) SRMockSSEResponderBeforeDataBlock beforeData;
@property (readwrite, nonatomic, copy) SRMockSSEResponderAfterDataBlock afterData;
@property (readwrite, nonatomic, copy) SRMockSSEResponderBeforeEndBlock beforeEnd;
@property (readwrite, nonatomic, copy) SRMockSSEResponderFailWithErrorBlock failWithError;
@property (readwrite, nonatomic, copy) SRMockSSEResponderAfterEndBlock afterEnd;

@property id<NSURLProtocolClient> client;
@property NSURLProtocol * protocol;

@end

@implementation SRMockSSEResponder

- (instancetype)initWithStatusCode:(NSInteger)statusCode
                       eventStream:(NSArray<NSData *> * _Nullable)eventStream {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    
    self.bodyChunks = eventStream;
    _statusCode = statusCode;
    
    return self;
}

- (void)respondToMockRequest:(id<UMKMockURLRequest>)request client:(id<NSURLProtocolClient>)client protocol:(NSURLProtocol *)protocol; {
    self.client = client;
    self.protocol = protocol;
    self.responding = YES;
    
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:protocol.request.URL
                                                              statusCode:self.statusCode
                                                             HTTPVersion:@"HTTP/1.1"
                                                            headerFields:@{
                                                                @"Content-Type":@"text/event-stream"
                                                            }];
    
    // Stop if we were canceled in another thread.
    if (!self.responding) {
        return;
    }
    
    if(self.beforeStart) {
        self.beforeStart();
    }
    [client URLProtocol:protocol didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [NSThread sleepForTimeInterval:.1];
    if (self.afterStart) {
        self.afterStart();
    }
    
    [self eventStream:self.bodyChunks];
    
    if (!self.responding) {
        return;
    }
    
    if (self.statusCode != 0) {
        [NSThread sleepForTimeInterval:1];
        
        if (self.statusCode == 200) {
            if (self.beforeEnd) {
                self.beforeEnd(nil);
            }
            [client URLProtocolDidFinishLoading:protocol];
            [NSThread sleepForTimeInterval:.1];
            if (self.afterEnd) {
                self.afterEnd(nil);
            }
        } else {
            NSError *error = (self.failWithError) ? self.failWithError() : [NSError errorWithDomain:@"UnitTesting" code:NSURLErrorUnknown userInfo:nil];
            if (self.beforeEnd) {
                self.beforeEnd(error);
            }
            [client URLProtocol:protocol didFailWithError:error];
            [NSThread sleepForTimeInterval:.1];
            if (self.afterEnd) {
                self.afterEnd(error);
            }
        }
        self.responding = NO;
    }
}

- (instancetype)beforeStart:(nullable void (^)(void))block; {
    self.beforeStart = block;
    return self;
}
- (instancetype)afterStart:(nullable void (^)(void))block {
    self.afterStart = block;
    return self;
}

- (instancetype)beforeData:(nullable void (^)(NSData * _Nonnull data))block; {
    self.beforeData = block;
    return self;
}

- (instancetype)afterData:(nullable void (^)(NSData * _Nonnull data))block; {
    self.afterData = block;
    return self;
}

- (instancetype)beforeEnd:(nullable void (^)(NSError * _Nullable error))block; {
    self.beforeEnd = block;
    return self;
}

- (instancetype)failWithError:(nullable NSError * (^)(void))block; {
    self.failWithError = block;
    return self;
}

- (instancetype)afterEnd:(nullable void (^)(NSError * _Nullable error))block; {
    self.afterEnd = block;
    return self;
}

- (void)eventStream:(NSArray<NSData *> * _Nullable)bodyChunks {
    if (bodyChunks) {
        __weak __typeof(&*self)weakSelf = self;
        [bodyChunks enumerateObjectsUsingBlock:^(NSData * _Nonnull data, NSUInteger idx, BOOL * _Nonnull stop) {
            __strong __typeof(&*weakSelf)strongSelf = weakSelf;
            if (strongSelf.beforeData) {
                strongSelf.beforeData(data);
            }
            [strongSelf.client URLProtocol:strongSelf.protocol didLoadData:data];
            [NSThread sleepForTimeInterval:.1];
            if (strongSelf.afterData) {
                strongSelf.afterData(data);
            }
        }];
        
        if (!self.responding) {
            return;
        }
    }
}

- (void)cancelResponse {
    self.responding = NO;
}

@end
