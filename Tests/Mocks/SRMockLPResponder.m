//
//  SRMockLPResponder.m
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 7/27/16.
//  Copyright © 2016 DyKnow LLC. All rights reserved.
//

#import "SRMockLPResponder.h"

typedef void (^SRMockLPResponderBeforeStartBlock)(void);
typedef void (^SRMockLPResponderAfterStartBlock)(void);
typedef void (^SRMockLPResponderBeforeDataBlock)(NSData * _Nonnull data);
typedef void (^SRMockLPResponderAfterDataBlock)(NSData * _Nonnull data);
typedef void (^SRMockLPResponderBeforeEndBlock)(NSError * _Nullable error);
typedef NSError * (^SRMockLPResponderFailWithErrorBlock)(void);
typedef void (^SRMockLPResponderAfterEndBlock)(NSError * _Nullable error);

@interface SRMockLPResponder ()

@property (readwrite, nonatomic) NSArray<NSData *> * bodyChunks;

/*! The HTTP status code that the instance responds with. */
@property (readonly, nonatomic) NSInteger statusCode;

- (instancetype)init NS_UNAVAILABLE;

/*! Whether the responder is currently responding to a request. */
@property (nonatomic, getter = isResponding) BOOL responding;

@property (readwrite, nonatomic, copy) SRMockLPResponderBeforeStartBlock beforeStart;
@property (readwrite, nonatomic, copy) SRMockLPResponderAfterStartBlock afterStart;
@property (readwrite, nonatomic, copy) SRMockLPResponderBeforeDataBlock beforeData;
@property (readwrite, nonatomic, copy) SRMockLPResponderAfterDataBlock afterData;
@property (readwrite, nonatomic, copy) SRMockLPResponderBeforeEndBlock beforeEnd;
@property (readwrite, nonatomic, copy) SRMockLPResponderFailWithErrorBlock failWithError;
@property (readwrite, nonatomic, copy) SRMockLPResponderAfterEndBlock afterEnd;

@end

@implementation SRMockLPResponder

+ (instancetype)mockHTTPResponderWithStatusCode:(NSInteger)statusCode
{
    return [[self alloc] initWithStatusCode:statusCode headers:nil body:nil];
}

- (instancetype)initWithStatusCode:(NSInteger)statusCode
                           headers:(NSDictionary<NSString *, NSString *> * _Nullable)headers
                              body:(NSData *)body {
    self = [super init];
    if (self) {
        self.body = body;
        self.headers = headers;
        _statusCode = statusCode;
    }
    
    return self;
}

- (void)respondToMockRequest:(id<UMKMockURLRequest>)request client:(id<NSURLProtocolClient>)client protocol:(NSURLProtocol *)protocol {
    self.responding = YES;
    
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:protocol.request.URL
                                                              statusCode:self.statusCode
                                                             HTTPVersion:@"HTTP/1.1"
                                                            headerFields:self.headers];
    
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
    
    if (self.body) {
        if (self.beforeData) {
            self.beforeData(self.body);
        }
        [client URLProtocol:protocol didLoadData:self.body];
        [NSThread sleepForTimeInterval:.1];
        if (self.afterData) {
            self.afterData(self.body);
        }
    }
    
    if (!self.responding) {
        return;
    }
    
    if (self.statusCode != 0) {
        [NSThread sleepForTimeInterval:.1];
        
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

- (void)cancelResponse {
    self.responding = NO;
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

@end
