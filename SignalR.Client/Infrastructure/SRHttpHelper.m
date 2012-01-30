//
//  SRHttpHelper.m
//  SignalR
//
//  Created by Alex Billingsley on 10/18/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "SRHttpHelper.h"
#import "SRSignalRConfig.h"

#import "SBJson.h"
#import "AFNetworking.h"
#import "NSDictionary+QueryString.h"

@interface SRHttpHelper ()

#pragma mark - 
#pragma mark GET Requests Implementation

/**
 * Helper for getAsync functions, performs the GET request
 * Subclasses should override this function 
 *
 * @param url: The url relative to the server endpoint
 * @param parameters: An Object that conforms to proxyForJSON to pass as parameters to the endpoint
 * @param requestPreparer: A function to be called on the NSMutableURLRequest created for the request
 * This can be used to modify properties of the POST, for example timeout or cache protocol
 * @param block: A function to be called when the post finishes. The block should handle both SUCCESS and FAILURE
 */
- (void)getInternal:(NSString *)url requestPreparer:(void(^)(id))requestPreparer parameters:(id)parameters continueWith:(void (^)(id response))block;

#pragma mark - 
#pragma mark POST Requests Implementation

/**
 * Helper for postAsync functions, performs the POST request
 * Subclasses should override this function 
 *
 * @param url: The url relative to the server endpoint
 * @param postData: An Object that conforms to proxyForJSON to post at the url
 * @param requestPreparer: A function to be called on the NSMutableURLRequest created for the request
 * This can be used to modify properties of the POST, for example timeout or cache protocol
 * @param block: A function to be called when the post finishes. The block should handle both SUCCESS and FAILURE
 */
- (void)postInternal:(NSString *)url requestPreparer:(void(^)(id))requestPreparer postData:(id)postData continueWith:(void (^)(id response))block;

@end

static id sharedHttpRequestManager = nil;

@implementation SRHttpHelper

+ (id)sharedHttpRequestManager
{
    if (sharedHttpRequestManager == nil) {
		sharedHttpRequestManager = [[self alloc] init];
	}
	return sharedHttpRequestManager;
}

#pragma mark - 
#pragma mark GET Requests Implementation

+ (void)getAsync:(NSString *)url continueWith:(void (^)(id response))block
{
     [[self class] getAsync:url requestPreparer:nil continueWith:block];
}

+ (void)getAsync:(NSString *)url requestPreparer:(void(^)(id))requestPreparer continueWith:(void (^)(id response))block
{
    [[self class] getAsync:url requestPreparer:requestPreparer parameters:[[NSDictionary alloc] init] continueWith:block];
}

+ (void)getAsync:(NSString *)url parameters:(id)parameters continueWith:(void (^)(id response))block;
{
    [[self class] getAsync:url requestPreparer:nil parameters:parameters continueWith:block];
}

+ (void)getAsync:(NSString *)url requestPreparer:(void(^)(id))requestPreparer parameters:(id)parameters continueWith:(void (^)(id response))block
{
    [[self sharedHttpRequestManager] getInternal:url requestPreparer:requestPreparer parameters:parameters continueWith:block];
}

- (void)getInternal:(NSString *)url requestPreparer:(void(^)(id))requestPreparer parameters:(id)parameters continueWith:(void (^)(id response))block
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"Keep-Alive" forHTTPHeaderField:@"Connection"];
    if(requestPreparer != nil)
    {
        requestPreparer(request);
    }
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    if(requestPreparer != nil)
    {
        requestPreparer(operation);
    }
    NSOutputStream *oStream = [NSOutputStream outputStreamToMemory];
    if(block)
    {
        block(oStream);
    }
    operation.outputStream = oStream;
    [operation start];
}

#pragma mark - 
#pragma mark POST Requests Implementation

+ (void)postAsync:(NSString *)url continueWith:(void (^)(id response))block
{
    [[self class] postAsync:url requestPreparer:nil continueWith:block];
}

+ (void)postAsync:(NSString *)url requestPreparer:(void(^)(id))requestPreparer continueWith:(void (^)(id response))block
{
    [[self class] postAsync:url requestPreparer:requestPreparer postData:[[NSDictionary alloc] init] continueWith:block];
}

+ (void)postAsync:(NSString *)url postData:(id)postData continueWith:(void (^)(id response))block
{
    [[self class] postAsync:url requestPreparer:nil postData:postData continueWith:block];
}

+ (void)postAsync:(NSString *)url requestPreparer:(void(^)(id))requestPreparer postData:(id)postData continueWith:(void (^)(id response))block
{
    [[self sharedHttpRequestManager] postInternal:url requestPreparer:requestPreparer postData:postData continueWith:block];
}

- (void)postInternal:(NSString *)url requestPreparer:(void(^)(id))requestPreparer postData:(id)postData continueWith:(void (^)(id response))block
{
    NSData *requestData = [[postData stringWithFormEncodedComponents] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%d", [requestData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody: requestData];
    if(requestPreparer != nil)
    {
        requestPreparer(request);
    }
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    if(requestPreparer != nil)
    {
        requestPreparer(operation);
    }
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) 
    {
        if (block)
        {
            block(operation.responseString);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) 
    {
        if (block)
        {
            block(error);
        }
    }];
    [operation start];
}

@end
