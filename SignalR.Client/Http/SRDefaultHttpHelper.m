//
//  SRDefaultHttpHelper.m
//  SignalR
//
//  Created by Alex Billingsley on 6/6/12.
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

#import "AFURLConnectionOperation.h"
#import "AFHTTPRequestOperation.h"
#import "SRDefaultHttpHelper.h"
#import "SRLog.h"

@interface SRHTTPRequestOperation : AFHTTPRequestOperation

typedef void (^AFURLConnectionOperationDidReceiveURLResponseBlock)(AFHTTPRequestOperation *operation, NSHTTPURLResponse *response);

@property (readwrite, nonatomic, strong) NSHTTPURLResponse *response;
@property (readwrite, nonatomic, copy) AFURLConnectionOperationDidReceiveURLResponseBlock urlResponseBlock;

@end

@implementation SRHTTPRequestOperation

@dynamic response;

- (void)setDidReceiveResponseBlock:(void (^)(AFHTTPRequestOperation *operation, NSHTTPURLResponse *response))block {
    self.urlResponseBlock = block;
}

#pragma mark -
#pragma mark NSURLConnection Delegate

- (void)connection:(NSURLConnection *)__unused connection
didReceiveResponse:(NSURLResponse *)response {
    self.response = (NSHTTPURLResponse *)response;
    if (self.urlResponseBlock) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.urlResponseBlock(self, self.response);
        });
    }
    [super connection:connection didReceiveResponse:response];
}

@end

@interface SRDefaultHttpHelper ()

#pragma mark - 
#pragma mark GET Requests Implementation

/**
 * Helper for getAsync functions, performs the GET request
 * Subclasses should override this function 
 *
 * @param url: The url relative to the server endpoint
 * @param parameters: An Object that conforms to SRSerializable to pass as parameters to the endpoint
 * @param requestPreparer: A function to be called on the NSMutableURLRequest created for the request
 * This can be used to modify properties of the POST, for example timeout or cache protocol
 * @param block: A function to be called when the post finishes. The block should handle both SUCCESS and FAILURE
 */
+ (void)getInternal:(NSString *)url requestPreparer:(SRPrepareRequestBlock)requestPreparer parameters:(id)parameters completionHandler:(SRCompletionHandler)block;

#pragma mark - 
#pragma mark POST Requests Implementation

/**
 * Helper for postAsync functions, performs the POST request
 * Subclasses should override this function 
 *
 * @param url: The url relative to the server endpoint
 * @param postData: An Object that conforms to SRSerializable to post at the url
 * @param requestPreparer: A function to be called on the NSMutableURLRequest created for the request
 * This can be used to modify properties of the POST, for example timeout or cache protocol
 * @param block: A function to be called when the post finishes. The block should handle both SUCCESS and FAILURE
 */
+ (void)postInternal:(NSString *)url requestPreparer:(SRPrepareRequestBlock)requestPreparer postData:(id)postData completionHandler:(SRCompletionHandler)block;

@end

@implementation SRDefaultHttpHelper

#pragma mark - 
#pragma mark GET Requests Implementation

+ (void)getAsync:(NSString *)url completionHandler:(SRCompletionHandler)block {
    [[self class] getAsync:url requestPreparer:nil completionHandler:block];
}

+ (void)getAsync:(NSString *)url requestPreparer:(SRPrepareRequestBlock)requestPreparer completionHandler:(SRCompletionHandler)block {
    [[self class] getAsync:url requestPreparer:requestPreparer parameters:[[NSDictionary alloc] init] completionHandler:block];
}

+ (void)getAsync:(NSString *)url parameters:(id)parameters completionHandler:(SRCompletionHandler)block {
    [[self class] getAsync:url requestPreparer:nil parameters:parameters completionHandler:block];
}

+ (void)getAsync:(NSString *)url requestPreparer:(SRPrepareRequestBlock)requestPreparer parameters:(id)parameters completionHandler:(SRCompletionHandler)block {
    [[self class] getInternal:url requestPreparer:requestPreparer parameters:parameters completionHandler:block];
}

+ (void)getInternal:(NSString *)url requestPreparer:(SRPrepareRequestBlock)requestPreparer parameters:(id)parameters completionHandler:(SRCompletionHandler)block {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"Keep-Alive" forHTTPHeaderField:@"Connection"];
    [request setTimeoutInterval:240];
    if(requestPreparer != nil) {
        requestPreparer(request);
    }
    SRLogHTTP(@"%@",[NSString stringWithFormat:@"%@: %@\nHEADERS=%@\nBODY=%@\nTIMEOUT=%f\n",request.HTTPMethod,[request.URL absoluteString],request.allHTTPHeaderFields,[[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding], request.timeoutInterval]);

    AFHTTPRequestOperation *operation = [[SRHTTPRequestOperation alloc] initWithRequest:request];
    if(requestPreparer != nil) {
        requestPreparer(operation);
    }
    
    [(SRHTTPRequestOperation *)operation setDidReceiveResponseBlock:^(AFHTTPRequestOperation *operation, NSHTTPURLResponse *response) {
        if([(operation.request.allHTTPHeaderFields)[@"Accept"] isEqualToString:@"text/event-stream"] && block) {
            NSOutputStream *oStream = [NSOutputStream outputStreamToMemory];
            [operation setOutputStream:oStream];
            block(oStream);
        }
    }];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        SRLogHTTP(@"%@",[NSString stringWithFormat:@"Request (%@ %@) was successful\nRESPONSE=%@ \n",operation.request.HTTPMethod,[operation.request.URL absoluteString],operation.responseString]);
        
        if (block) {
            block(([(operation.request.allHTTPHeaderFields)[@"Accept"] isEqualToString:@"text/event-stream"]) ? nil : operation.responseString);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        SRLogHTTP(@"%@",[NSString stringWithFormat:@"Request (%@ %@) failed\nERROR=%@ \n",operation.request.HTTPMethod,[operation.request.URL absoluteString],error]);
        
        if (block) {
            block(error);
        }
    }];
    [operation start];
}

#pragma mark -
#pragma mark POST Requests Implementation

+ (void)postAsync:(NSString *)url completionHandler:(SRCompletionHandler)block {
    [[self class] postAsync:url requestPreparer:nil completionHandler:block];
}

+ (void)postAsync:(NSString *)url requestPreparer:(SRPrepareRequestBlock)requestPreparer completionHandler:(SRCompletionHandler)block {
    [[self class] postAsync:url requestPreparer:requestPreparer postData:[[NSDictionary alloc] init] completionHandler:block];
}

+ (void)postAsync:(NSString *)url postData:(id)postData completionHandler:(SRCompletionHandler)block {
    [[self class] postAsync:url requestPreparer:nil postData:postData completionHandler:block];
}

+ (void)postAsync:(NSString *)url requestPreparer:(SRPrepareRequestBlock)requestPreparer postData:(id)postData completionHandler:(SRCompletionHandler)block {
    [[self class] postInternal:url requestPreparer:requestPreparer postData:postData completionHandler:block];
}

+ (void)postInternal:(NSString *)url requestPreparer:(SRPrepareRequestBlock)requestPreparer postData:(id)postData completionHandler:(SRCompletionHandler)block {
    NSMutableArray *components = [NSMutableArray array];
    for (NSString *key in [postData allKeys]) {
        [components addObject:[NSString stringWithFormat:@"%@=%@",key,postData[key]]];
    }
    NSData *requestData = [[components componentsJoinedByString:@"&"] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%ld", (unsigned long)[requestData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody: requestData];
    [request setTimeoutInterval:240];
    if(requestPreparer != nil) {
        requestPreparer(request);
    }
    SRLogHTTP(@"%@",[NSString stringWithFormat:@"%@: %@\nHEADERS=%@\nBODY=%@\nTIMEOUT=%f\n",request.HTTPMethod,[request.URL absoluteString],request.allHTTPHeaderFields,[[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding], request.timeoutInterval]);
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    if(requestPreparer != nil) {
        requestPreparer(operation);
    }
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        SRLogHTTP(@"%@",[NSString stringWithFormat:@"Request (%@ %@) was successful\nRESPONSE=%@ \n",operation.request.HTTPMethod,[operation.request.URL absoluteString],operation.responseString]);

        if (block) {
            block(operation.responseString);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        SRLogHTTP(@"%@",[NSString stringWithFormat:@"Request (%@ %@) failed\nERROR=%@ \n",operation.request.HTTPMethod,[operation.request.URL absoluteString],error]);

        if (block) {
            block(error);
        }
    }];
    [operation start];
}

@end
