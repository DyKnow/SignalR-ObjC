//
//  SRMockSSEResponder.h
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 7/7/16.
//  Copyright © 2016 DyKnow LLC. All rights reserved.
//

#import <URLMock/UMKMockHTTPMessage.h>
#import <URLMock/UMKMockURLProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface SRMockSSEResponder : UMKMockHTTPMessage <UMKMockURLResponder>

- (instancetype)initWithStatusCode:(NSInteger)statusCode
                       eventStream:(NSArray<NSData *> * _Nullable)eventStream;

- (instancetype)beforeStart:(nullable void (^)(void))block;
- (instancetype)afterStart:(nullable void (^)(void))block;
                            
- (instancetype)beforeData:(nullable void (^)(NSData * _Nonnull data))block;
- (instancetype)afterData:(nullable void (^)(NSData * _Nonnull data))block;

- (instancetype)beforeEnd:(nullable void (^)(NSError * _Nullable error))block;
- (instancetype)failWithError:(nullable NSError * (^)(void))block;
- (instancetype)afterEnd:(nullable void (^)(NSError * _Nullable error))block;

- (void)eventStream:(NSArray<NSData *> * _Nullable)bodyChunks;

@end

NS_ASSUME_NONNULL_END