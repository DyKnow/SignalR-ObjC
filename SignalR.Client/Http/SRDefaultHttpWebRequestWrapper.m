//
//  SRDefaultHttpWebRequestWrapper.m
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

#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"
#import "SRDefaultHttpWebRequestWrapper.h"

@interface SRDefaultHttpWebRequestWrapper ()

@property (strong, nonatomic, readwrite) NSMutableURLRequest *request;
@property (weak, nonatomic, readwrite) AFHTTPRequestOperation *requestOperation;

@end

@implementation SRDefaultHttpWebRequestWrapper

@synthesize userAgent = _userAgent;
@synthesize timeoutInterval = _timeoutInterval;
@synthesize credentials = _credentials;
@synthesize headers = _headers;
@synthesize accept = _accept;

- (instancetype)initWithRequest:(id)request {
    if (self = [super init]) {
        if([request isKindOfClass:[NSMutableURLRequest class]]) {
            _request = request;
        } else if([request isKindOfClass:[AFHTTPRequestOperation class]]) {
            _requestOperation = request;
        }
    }
    return self;
}

- (void)setUserAgent:(NSString *)userAgent {
    _userAgent = userAgent;
    
    if(_request && _userAgent) {
        [_request addValue:_userAgent forHTTPHeaderField:@"User-Agent"];
    }
}

- (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval {
    _timeoutInterval = timeoutInterval;
    
    if(_request && _timeoutInterval) {
        [_request setTimeoutInterval:_timeoutInterval];
    }
}
- (void)setCredentials:(NSURLCredential *)credentials {
    _credentials = credentials;
    
    if(_request && _credentials) {
        // Create a AFHTTPClient for the sole purpose of generating an authorization header.
        AFHTTPClient *clientForAuthHeader = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
        [clientForAuthHeader setAuthorizationHeaderWithUsername:_credentials.user password:_credentials.password];
        
        //Set the Authorization header that we just generated to our actual request
        [_request addValue:[clientForAuthHeader defaultValueForHeader:@"Authorization"] forHTTPHeaderField:@"Authorization"];
    }
}

- (void)setHeaders:(NSMutableDictionary *)headers {
    _headers = headers;
    
    if(_request && _headers) {
        for(NSString *header in _headers) {
            [_request addValue:[_headers valueForKey:header] forHTTPHeaderField:header];
        }
    }
}

- (void)setAccept:(NSString *)accept {
    _accept = accept;
    
    if(_request && _accept) {
        [_request addValue:_accept forHTTPHeaderField:@"Accept"];
    }
}

- (void)abort {
    if(_requestOperation) {
        [_requestOperation cancel];
    }
}

@end
