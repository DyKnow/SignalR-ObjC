//
//  SRHttpHelper.m
//  SignalR
//
//  Created by Alex Billingsley on 10/18/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "SRHttpHelper.h"

#import "SBJson.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "NSDictionary+QueryString.h"

@interface SRHttpHelper()

@end

@implementation SRHttpHelper

@synthesize queue = _queue;

#pragma mark - 
#pragma mark GET Requests Implementation

//TODO: Handle Request Preparer
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
    
#if DEBUG
    NSLog(@"%@",[request.url absoluteString]);
#endif
    
    [request setCompletionBlock:^{
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
    
#if DEBUG
    NSLog(@"%@",[request.url absoluteString]);
    NSLog(@"%@",[postData stringWithFormEncodedComponents]);
#endif
    [request setCompletionBlock:^{
        if(block){
            block([request responseString]);
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
