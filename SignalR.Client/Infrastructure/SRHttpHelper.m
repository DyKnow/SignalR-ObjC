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

@interface SRHttpHelper()

@end

@implementation SRHttpHelper

@synthesize queue = _queue;

#pragma mark - 
#pragma mark GET Requests Implementation

//TODO: Handle Request Preparer
- (void)getInternal:(NSString *)url requestPreparer:(void(^)(NSMutableURLRequest *))requestPreparer parameters:(id)parameters continueWith:(void(^)(id))block
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

//TODO: Handle Request Preparer
- (void)postInternal:(NSString *)url requestPreparer:(void(^)(NSMutableURLRequest *))requestPreparer postData:(id)postData continueWith:(void(^)(id))block
{
    if (!_queue) {
        _queue = [[NSOperationQueue alloc] init];
    }
    
    ASIFormDataRequest *_request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:url]];
    __weak ASIHTTPRequest *request = _request;

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
