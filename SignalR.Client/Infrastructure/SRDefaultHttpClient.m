//
//  DefaultHttpClient.m
//  SignalR.Samples
//
//  Created by Alex Billingsley on 3/23/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import "SRDefaultHttpClient.h"

#import "SRHttpHelper.h"

@implementation SRDefaultHttpClient

- (void)getAsync:(NSString *)url requestPreparer:(void(^)(id))prepareRequest continueWith:(void (^)(id response))block
{
    [SRHttpHelper getAsync:url requestPreparer:prepareRequest continueWith:block];
}

- (void)postAsync:(NSString *)url requestPreparer:(void(^)(id))prepareRequest continueWith:(void (^)(id response))block
{
    [SRHttpHelper postAsync:url requestPreparer:prepareRequest continueWith:block];
}

- (void)postAsync:(NSString *)url requestPreparer:(void(^)(id))prepareRequest postData:(id)postData continueWith:(void (^)(id response))block
{
    [SRHttpHelper postAsync:url requestPreparer:prepareRequest postData:postData continueWith:block];
}

@end
