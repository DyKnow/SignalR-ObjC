//
//  SRLongPollingTransport.m
//  SignalR
//
//  Created by Alex Billingsley on 10/17/11.
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

#import "AFHTTPRequestOperation.h"
#import "SRConnectionInterface.h"
#import "SRConnectionExtensions.h"
#import "SRExceptionHelper.h"
#import "SRLog.h"
#import "SRLongPollingTransport.h"

typedef void (^SRLongPollingInitializedBlock)(void);
typedef void (^SRLongPollingErrorBlock)(NSError *);

@interface SRLongPollingTransport()

@property (strong, nonatomic, readwrite) NSOperationQueue *pollingOperationQueue;
@property (copy) SRLongPollingInitializedBlock initializeCallback;
@property (copy) SRLongPollingErrorBlock errorCallback;

@end

@implementation SRLongPollingTransport

static NSString * const kTransportName = @"longPolling";

- (instancetype)init {
    if (self = [super init]) {
        _pollingOperationQueue = [[NSOperationQueue alloc] init];
        [_pollingOperationQueue setMaxConcurrentOperationCount:1];
        _reconnectDelay = @5;
        _errorDelay = @2;
        _connectDelay = @2;
    }
    return self;
}

#pragma mark 
#pragma mark SRClientTransportInterface

- (NSString *)name {
    return @"longPolling";
}

- (BOOL)supportsKeepAlive {
    return NO;
}

- (void)negotiate:(id <SRConnectionInterface>)connection completionHandler:(void (^)(SRNegotiationResponse *response))block {
    [super negotiate:connection completionHandler:block];
}

- (void)start:(id <SRConnectionInterface>)connection data:(NSString *)data completionHandler:(void (^)(id response))block {
    [self setInitializeCallback:^{
        if (block) {
            block(nil);
        }
    }];
    [self setErrorCallback:^(NSError * error){
        if (block) {
            block(error);
        }
    }];
    [self pollingLoop:connection data:data raiseReconnect:NO];
}

- (void)pollingLoop:(id <SRConnectionInterface>)connection data:(NSString *)data raiseReconnect:(BOOL)raiseReconnect {
    NSString *url = connection.url;
    if(connection.messageId == nil) {
        url = [url stringByAppendingString:@"connect"];
    } else if (raiseReconnect) {
        url = [url stringByAppendingString:@"reconnect"];
        
        if (connection.state == disconnected || ![SRConnection ensureReconnecting:connection]) {
            return;
        }
    }
    url = [url stringByAppendingString:[self receiveQueryString:connection data:data]];
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest setTimeoutInterval:240];

    [connection prepareRequest:urlRequest];
    
    __weak __typeof(&*self)weakSelf = self;
    __weak __typeof(&*connection)weakConnection = connection;
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;

        if (strongSelf.initializeCallback != nil) {
            strongSelf.initializeCallback();
            strongSelf.initializeCallback = nil;
        }
        
        if(raiseReconnect) {
            if ([strongConnection changeState:reconnecting toState:connected]) {
                SRLogLongPolling(@"did fire reconnected");
                [strongConnection didReconnect];
            }
        }
        
        if (strongSelf.errorCallback != nil) {
            strongSelf.errorCallback = nil;
        }
        
        BOOL shouldRaiseReconnect = NO;
        BOOL disconnectedReceived = NO;
        
        SRLogLongPolling(@"LP Receive: %@", operation.responseString);
        
        [strongSelf processResponse:strongConnection response:operation.responseString timedOut:&shouldRaiseReconnect disconnected:&disconnectedReceived];
        if(disconnectedReceived) {
            SRLogLongPolling(@"did disconnect");
            [strongConnection disconnect];
        } else if (connection.state != disconnected) {
            SRLogLongPolling(@"will poll again immediately");
            [strongSelf pollingLoop:strongConnection data:data raiseReconnect:shouldRaiseReconnect];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;

        if (strongSelf.errorCallback) {
            strongSelf.errorCallback(error);
            strongSelf.errorCallback = nil;
        } else {
            BOOL requestAborted = [SRExceptionHelper isRequestAborted:error];
            if(!requestAborted) {
                //Raise Error
                [strongConnection didReceiveError:error];
                SRLogLongPolling(@"will poll again in %ld seconds",(long)[_errorDelay integerValue]);
                [[NSBlockOperation blockOperationWithBlock:^{
                    if (connection.state != disconnected) {
                        [strongSelf pollingLoop:strongConnection data:data raiseReconnect:YES];
                    }
                }] performSelector:@selector(start) withObject:nil afterDelay:[strongSelf.errorDelay integerValue]];
            }
        }
    }];
    [self.pollingOperationQueue addOperation:operation];
    
    if (self.initializeCallback != nil) {
        [[NSBlockOperation blockOperationWithBlock:^{
            __strong __typeof(&*weakSelf)strongSelf = weakSelf;
            
            if (strongSelf.initializeCallback != nil) {
                strongSelf.initializeCallback();
                strongSelf.initializeCallback = nil;
            }
        }] performSelector:@selector(start) withObject:nil afterDelay:[self.connectDelay integerValue]];
    }
}

- (void)send:(id <SRConnectionInterface>)connection data:(NSString *)data completionHandler:(void (^)(id response))block {
    [super send:connection data:data completionHandler:block];
}

- (void)abort:(id <SRConnectionInterface>)connection timeout:(NSNumber *)timeout {
    [super abort:connection timeout:timeout];
}

@end
