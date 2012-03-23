//
//  SRHttpClient.h
//  SignalR.Samples
//
//  Created by Alex Billingsley on 3/23/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SRHttpClient <NSObject>

- (void)getAsync:(NSString *)url requestPreparer:(void(^)(id))prepareRequest continueWith:(void (^)(id response))block;

- (void)postAsync:(NSString *)url requestPreparer:(void(^)(id))prepareRequest continueWith:(void (^)(id response))block;
- (void)postAsync:(NSString *)url requestPreparer:(void(^)(id))prepareRequest postData:(id)postData continueWith:(void (^)(id response))block;

@end
