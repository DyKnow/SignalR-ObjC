//
//  SRHttpHelper.m
//  SignalR
//
//  Created by Alex Billingsley on 10/18/11.
//  Copyright (c) 2011 DyKnow LLC. (http://dyknow.com/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
//  documentation files (the "Software"), to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and 
//  to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of 
//  the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
//  THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
//  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
//  DEALINGS IN THE SOFTWARE.
//

#import "SRHttpHelper.h"
#import "SRSignalRConfig.h"

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
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"Keep-Alive" forHTTPHeaderField:@"Connection"];
    [request setTimeoutInterval:240];
    if(requestPreparer != nil)
    {
        requestPreparer(request);
    }
#if DEBUG_HTTP_HELPER
    NSString *debugOutput = [NSString stringWithFormat:@"%@ %@\n",request.HTTPMethod,[request.URL absoluteString]];
    debugOutput = [debugOutput stringByAppendingFormat:@"HEADERS=%@ \n",request.allHTTPHeaderFields];
    debugOutput = [debugOutput stringByAppendingFormat:@"BODY=%@ \n",request.HTTPBody];
    debugOutput = [debugOutput stringByAppendingFormat:@"TIMEOUT=%@ \n",request.timeoutInterval];
    SR_DEBUG_LOG(@"[HTTPHELPER] %@",debugOutput);
#endif
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
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) 
    {
#if DEBUG_HTTP_HELPER
        NSString *debugOutput = [NSString stringWithFormat:@"Request (%@ %@) was successful\n",operation.request.HTTPMethod,[operation.request.URL absoluteString]];
        debugOutput = [debugOutput stringByAppendingFormat:@"RESPONSE=%@ \n",operation.responseString];
        SR_DEBUG_LOG(@"[HTTPHELPER] %@",debugOutput);
#endif
        if (block)
        {
            block(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) 
    {
#if DEBUG_HTTP_HELPER
        NSString *debugOutput = [NSString stringWithFormat:@"Request (%@ %@) failed \n",operation.request.HTTPMethod,[operation.request.URL absoluteString]];
        debugOutput = [debugOutput stringByAppendingFormat:@"ERROR=%@ \n",error];
        SR_DEBUG_LOG(@"[HTTPHELPER] %@",debugOutput);
#endif
        if (block)
        {
            block(error);
        }
    }];
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
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%d", [requestData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody: requestData];
    [request setTimeoutInterval:240];
    if(requestPreparer != nil)
    {
        requestPreparer(request);
    }
#if DEBUG_HTTP_HELPER
    NSString *debugOutput = [NSString stringWithFormat:@"%@ %@\n",request.HTTPMethod,[request.URL absoluteString]];
    debugOutput = [debugOutput stringByAppendingFormat:@"HEADERS=%@ \n",request.allHTTPHeaderFields];
    debugOutput = [debugOutput stringByAppendingFormat:@"BODY=%@ \n",request.HTTPBody];
    debugOutput = [debugOutput stringByAppendingFormat:@"TIMEOUT=%@ \n",request.timeoutInterval];
    SR_DEBUG_LOG(@"[HTTPHELPER] %@",debugOutput);
#endif
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    if(requestPreparer != nil)
    {
        requestPreparer(operation);
    }
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) 
    {
#if DEBUG_HTTP_HELPER
        NSString *debugOutput = [NSString stringWithFormat:@"Request (%@ %@) was successful\n",operation.request.HTTPMethod,[operation.request.URL absoluteString]];
        debugOutput = [debugOutput stringByAppendingFormat:@"RESPONSE=%@ \n",operation.responseString];
        SR_DEBUG_LOG(@"[HTTPHELPER] %@",debugOutput);
#endif
        if (block)
        {
            block(operation.responseString);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) 
    {
#if DEBUG_HTTP_HELPER
        NSString *debugOutput = [NSString stringWithFormat:@"Request (%@ %@) failed \n",operation.request.HTTPMethod,[operation.request.URL absoluteString]];
        debugOutput = [debugOutput stringByAppendingFormat:@"ERROR=%@ \n",error];
        SR_DEBUG_LOG(@"[HTTPHELPER] %@",debugOutput);
#endif
        if (block)
        {
            block(error);
        }
    }];
    [operation start];
}

@end
