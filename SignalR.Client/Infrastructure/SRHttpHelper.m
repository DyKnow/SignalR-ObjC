//
//  SRHttpHelper.m
//  SignalR
//
//  Created by Alex Billingsley on 10/18/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "SRHttpHelper.h"

#import "SBJson.h"
#import "ASIFormDataRequest.h"
#import "NSDictionary+QueryString.h"

@interface SRHttpHelper()

#define DEBUG_VERBOSE 0

@end

static id sharedHttpRequestManager = nil;

@implementation SRHttpHelper

@synthesize queue = _queue;

+ (id)sharedHttpRequestManager
{
    if (sharedHttpRequestManager == nil) {
		sharedHttpRequestManager = [[self alloc] init];
	}
	return sharedHttpRequestManager;
}

#pragma mark - 
#pragma mark GET Requests Implementation

- (void)getInternal:(NSString *)url requestPreparer:(void(^)(id))requestPreparer parameters:(id)parameters continueWith:(void(^)(id))block
{
    if (!_queue) {
        _queue = [[NSOperationQueue alloc] init];
    }
        
    NSDictionary *dict = nil;
    if ([parameters respondsToSelector:@selector(proxyForJson)]) {
        dict = [parameters proxyForJson];
    }
    else if([parameters isKindOfClass:[NSDictionary class]]) {
        dict = parameters;
    }
    else {
        [NSException raise:@"InvalidParametersException" format:@"Parameters must respond to proxyForJson or be an NSDictionary"];
    }
    
    [ASIHTTPRequest setShouldUpdateNetworkActivityIndicator:NO];
    ASIFormDataRequest *_request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:url]];
    [_request setRequestMethod:@"GET"];
    for(NSString *key in dict)
    {
        [_request setPostValue:[dict objectForKey:key] forKey:key];
    }
    if(requestPreparer)
    {
        requestPreparer(_request);
    }
    __weak ASIFormDataRequest *request = _request;
    
#if DEBUG_VERBOSE
    NSLog(@"Url => %@",[request.url absoluteString]);
    NSLog(@"Headers => %@",[request requestHeaders]);
    NSLog(@"Cookies => %@",[request requestCookies]);
    NSLog(@"Method => %@",[request requestMethod]);
#endif
    
    [request setCompletionBlock:^{
#if DEBUG_VERBOSE
        NSLog(@"Headers => %@",[request responseHeaders]);
        NSLog(@"Code => %d",[request responseStatusCode]);
        NSLog(@"Status => %@",[request responseStatusMessage]);
#endif
        if(block){
            block([request responseData]);
        }
    }];
    [request setFailedBlock:^{
        if(block){
            block([request error]);
        }
    }];
    [_queue addOperation:request];
}

#pragma mark - 
#pragma mark POST Requests Implementation

- (void)postInternal:(NSString *)url requestPreparer:(void(^)(id))requestPreparer postData:(id)postData continueWith:(void(^)(id))block
{
    if (!_queue) {
        _queue = [[NSOperationQueue alloc] init];
    }

    NSData *requestData = [[postData stringWithFormEncodedComponents] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    
    [ASIHTTPRequest setShouldUpdateNetworkActivityIndicator:NO];
    ASIHTTPRequest *_request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
    [_request setRequestMethod:@"POST"];
    [_request addRequestHeader:@"Accept" value:@"application/json"];
    [_request addRequestHeader:@"Content-Type" value:@"application/x-www-form-urlencoded"];
    [_request addRequestHeader:@"Content-Length" value:[NSString stringWithFormat:@"%d", [requestData length]]];
    [_request appendPostData:requestData];
    if(requestPreparer)
    {
        requestPreparer(_request);
    }
    __weak ASIHTTPRequest *request = _request;

#if DEBUG_VERBOSE
    NSLog(@"Url => %@",[request.url absoluteString]);
    NSLog(@"Headers => %@",[request requestHeaders]);
    NSLog(@"Cookies => %@",[request requestCookies]);
    NSLog(@"Method => %@",[request requestMethod]);
#endif
    
    //When using ServerSentEvents Transport we need to intercept the data
    if([[_request.requestHeaders objectForKey:@"Accept"] isEqualToString:@"text/event-stream"])
    {
        if(block)
        {
            [request setDataReceivedBlock:^(NSData *data) {
#if DEBUG_VERBOSE
                NSLog(@"Headers => %@",[request responseHeaders]);
                NSLog(@"Code => %d",[request responseStatusCode]);
                NSLog(@"Status => %@",[request responseStatusMessage]);
#endif
                if([request responseStatusCode] != 200)
                {
                    block([NSError errorWithDomain:[request responseStatusMessage] code:[request responseStatusCode] userInfo:nil]);
                }
                else
                {
                    block([[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                }
            }];
        }
    }
    
    [request setCompletionBlock:^{
#if DEBUG_VERBOSE
        NSLog(@"Headers => %@",[request responseHeaders]);
        NSLog(@"Code => %d",[request responseStatusCode]);
        NSLog(@"Status => %@",[request responseStatusMessage]);
#endif
        if(block){
            if([request responseStatusCode] != 200)
            {
                block([NSError errorWithDomain:[request responseStatusMessage] code:[request responseStatusCode] userInfo:nil]);
            }
            else
            {
                block([request responseString]);
            }
        }
    }];
    [request setFailedBlock:^{
        if(block){
            block([request error]);
        }
    }];
    [_queue addOperation:request];
}

@end
