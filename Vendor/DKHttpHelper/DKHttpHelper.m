//
//  DKHttpHelper.m
//  DyKnow
//
//  Created by Alex Billingsley on 12/7/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "DKHttpHelper.h"

@interface DKHttpHelper()

@end

static id sharedHttpRequestManager = nil;

@implementation DKHttpHelper

#pragma mark - 
#pragma mark Initialization

+ (id)sharedHttpRequestManager {
	if (sharedHttpRequestManager == nil) {
		sharedHttpRequestManager = [[self alloc] init];
	}
	return sharedHttpRequestManager;
}

#pragma mark - 
#pragma mark GET Requests Implementation

+ (void)getAsync:(NSString *)url continueWith:(void(^)(id))block
{
    [[self sharedHttpRequestManager] getAsync:url continueWith:block];
}

- (void)getAsync:(NSString *)url continueWith:(void(^)(id))block
{
    [self getAsync:url requestPreparer:nil continueWith:block];
}

+ (void)getAsync:(NSString *)url requestPreparer:(void(^)(id))requestPreparer continueWith:(void(^)(id))block
{
    [[self sharedHttpRequestManager] getAsync:url requestPreparer:requestPreparer continueWith:block];
}

- (void)getAsync:(NSString *)url requestPreparer:(void(^)(id))requestPreparer continueWith:(void(^)(id))block
{
    [self postInternal:url requestPreparer:requestPreparer postData:[[NSDictionary alloc] init] continueWith:block];
}

+ (void)getAsync:(NSString *)url parameters:(id)parameters continueWith:(void(^)(id))block
{
    [[self sharedHttpRequestManager] getAsync:url parameters:parameters continueWith:block];
}

- (void)getAsync:(NSString *)url parameters:(id)parameters continueWith:(void(^)(id))block
{
    [self getAsync:url requestPreparer:nil parameters:parameters continueWith:block];
}

+ (void)getAsync:(NSString *)url requestPreparer:(void(^)(id))requestPreparer parameters:(id)parameters continueWith:(void(^)(id))block
{
    [[self sharedHttpRequestManager] getAsync:url requestPreparer:requestPreparer parameters:parameters continueWith:block];
}

- (void)getAsync:(NSString *)url requestPreparer:(void(^)(id))requestPreparer parameters:(id)parameters continueWith:(void(^)(id))block
{
    [self getInternal:url requestPreparer:nil parameters:parameters continueWith:block];
}

- (void)getInternal:(NSString *)url requestPreparer:(void(^)(id))requestPreparer parameters:(id)parameters continueWith:(void(^)(id))block
{
   
}

#pragma mark - 
#pragma mark POST Requests Implementation

+ (void)postAsync:(NSString *)url continueWith:(void(^)(id))block
{
    [[self sharedHttpRequestManager] postAsync:url continueWith:block];
}

- (void)postAsync:(NSString *)url continueWith:(void(^)(id))block
{
    [self postAsync:url requestPreparer:nil continueWith:block];
}

+ (void)postAsync:(NSString *)url requestPreparer:(void(^)(id))requestPreparer continueWith:(void(^)(id))block
{
    [[self sharedHttpRequestManager] postAsync:url requestPreparer:requestPreparer continueWith:block];
}

- (void)postAsync:(NSString *)url requestPreparer:(void(^)(id))requestPreparer continueWith:(void(^)(id))block
{
    [self postInternal:url requestPreparer:requestPreparer postData:[[NSDictionary alloc] init] continueWith:block];
}

+ (void)postAsync:(NSString *)url postData:(id)postData continueWith:(void(^)(id))block
{
    [[self sharedHttpRequestManager] postAsync:url postData:postData continueWith:block];
}

- (void)postAsync:(NSString *)url postData:(id)postData continueWith:(void(^)(id))block
{
    [self postAsync:url requestPreparer:nil postData:postData continueWith:block];
}

+ (void)postAsync:(NSString *)url requestPreparer:(void(^)(id))requestPreparer postData:(id)postData continueWith:(void(^)(id))block
{
    [[self sharedHttpRequestManager] postAsync:url requestPreparer:requestPreparer postData:postData continueWith:block];
}

- (void)postAsync:(NSString *)url requestPreparer:(void(^)(id))requestPreparer postData:(id)postData continueWith:(void(^)(id))block
{
    [self postInternal:url requestPreparer:nil postData:postData continueWith:block];
}

- (void)postInternal:(NSString *)url requestPreparer:(void(^)(id))requestPreparer postData:(id)postData continueWith:(void(^)(id))block
{  
    
}

@end
