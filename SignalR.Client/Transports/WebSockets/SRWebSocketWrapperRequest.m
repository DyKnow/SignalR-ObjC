//
//  SRWebSocketWrapperRequest.m
//  SignalR
//
//  Created by Alex Billingsley on 4/8/13.
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

#import "SRWebSocketWrapperRequest.h"
#import "SRWebSocket.h"

@interface SRWebSocketWrapperRequest ()

@property (strong, nonatomic, readonly) SRWebSocket *clientWebSocket;

@end

@implementation SRWebSocketWrapperRequest

@synthesize userAgent = _userAgent;
@synthesize timeoutInterval = _timeoutInterval;
@synthesize credentials = _credentials;
@synthesize headers = _headers;
@synthesize accept = _accept;

- (instancetype)initWithWebSocket:(SRWebSocket *)webSocket {
    if (self = [super init]) {
        _clientWebSocket = webSocket;
    }
    return self;
}

- (void)setUserAgent:(NSString *)userAgent {
    
}

- (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval {
    _timeoutInterval = timeoutInterval;
}
- (void)setCredentials:(NSURLCredential *)credentials {
    _credentials = credentials;
}

- (void)setHeaders:(NSMutableDictionary *)headers {
    _headers = headers;
}

- (void)setAccept:(NSString *)accept {
    
}

- (void)abort {

}

@end
