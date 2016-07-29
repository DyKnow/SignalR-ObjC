//
//  SRMockLPResponder.h
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 7/27/16.
//  Copyright © 2016 DyKnow LLC. All rights reserved.
//

#import <URLMock/UMKMockHTTPResponder.h>

NS_ASSUME_NONNULL_BEGIN

@interface SRMockLPResponder : UMKMockHTTPMessage <UMKMockURLResponder>

+ (instancetype)mockHTTPResponderWithStatusCode:(NSInteger)statusCode;

- (instancetype)initWithStatusCode:(NSInteger)statusCode
                           headers:(NSDictionary<NSString *, NSString *> * _Nullable)headers
                              body:(NSData * _Nullable)body;

- (instancetype)beforeStart:(nullable void (^)(void))block;
- (instancetype)afterStart:(nullable void (^)(void))block;

- (instancetype)beforeData:(nullable void (^)(NSData * _Nonnull data))block;
- (instancetype)afterData:(nullable void (^)(NSData * _Nonnull data))block;

- (instancetype)beforeEnd:(nullable void (^)(NSError * _Nullable error))block;
- (instancetype)failWithError:(nullable NSError * (^)(void))block;
- (instancetype)afterEnd:(nullable void (^)(NSError * _Nullable error))block;

@end

NS_ASSUME_NONNULL_END