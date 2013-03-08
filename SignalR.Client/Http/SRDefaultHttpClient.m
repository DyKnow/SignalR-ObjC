//
//  DefaultHttpClient.m
//  SignalR
//
//  Created by Alex Billingsley on 3/23/12.
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

#import "SRDefaultHttpClient.h"
#import "SRDefaultHttpHelper.h"
#import "SRDefaultHttpWebRequestWrapper.h"
#import "SRDefaultHttpWebResponseWrapper.h"

@implementation SRDefaultHttpClient

- (void)get:(NSString *)url requestPreparer:(SRRequestBlock)prepareRequest completionHandler:(SRResponseBlock)block {
    if (url == nil) {
        [NSException raise:NSInvalidArgumentException format:NSLocalizedString(@"Url should be non-null",@"")];
    }
    
    __block id <SRRequest> req = nil;
    [SRDefaultHttpHelper getAsync:url 
                  requestPreparer:^(id request) {
                      req = [[SRDefaultHttpWebRequestWrapper alloc] initWithRequest:request];
                      if (prepareRequest)
                          prepareRequest(req);
                  } completionHandler:^(id response) {
                      if (block)
                          block([[SRDefaultHttpWebResponseWrapper alloc] initWithRequest:req withResponse:response]);
                  }];
}

- (void)post:(NSString *)url requestPreparer:(SRRequestBlock)prepareRequest completionHandler:(SRResponseBlock)block {
    if (url == nil) {
        [NSException raise:NSInvalidArgumentException format:NSLocalizedString(@"Url should be non-null",@"")];
    }
    
    __block id <SRRequest> req = nil;
    [SRDefaultHttpHelper postAsync:url 
                   requestPreparer:^(id request) {
                       req = [[SRDefaultHttpWebRequestWrapper alloc] initWithRequest:request];
                       if (prepareRequest)
                           prepareRequest(req);
                   } completionHandler:^(id response) {
                       if (block)
                           block([[SRDefaultHttpWebResponseWrapper alloc] initWithRequest:req withResponse:response]);
                   }];
}

- (void)post:(NSString *)url requestPreparer:(SRRequestBlock)prepareRequest postData:(id)postData completionHandler:(SRResponseBlock)block {
    if (url == nil) {
        [NSException raise:NSInvalidArgumentException format:NSLocalizedString(@"Url should be non-null",@"")];
    }
    
    __block id <SRRequest> req = nil;
    [SRDefaultHttpHelper postAsync:url 
                   requestPreparer:^(id request) {
                       req = [[SRDefaultHttpWebRequestWrapper alloc] initWithRequest:request];
                       if (prepareRequest)
                           prepareRequest(req);
                   }
                          postData:postData
                       completionHandler:^(id response) { if (block) block([[SRDefaultHttpWebResponseWrapper alloc] initWithRequest:req withResponse:response]); }];
}

@end
