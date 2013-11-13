//
//  SRServerSentEventsTransport.m
//  SignalR
//
//  Created by Alex Billingsley on 1/7/12.
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
#import "SRServerSentEventsTransport.h"
#import "SRConnectionInterface.h"
#import "SREventSourceStreamReader.h"
#import "SRExceptionHelper.h"
#import "SRConnectionExtensions.h"
#import "SRLog.h"
#import "SRChunkBuffer.h"
#import "SRServerSentEvent.h"

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

typedef void (^SRCompletionHandler)(id response, NSError *error);

@interface SRServerSentEventsTransport ()

@property (assign) BOOL stop;
@property (strong, nonatomic, readwrite) NSOperationQueue *serverSentEventsOperationQueue;
@property (copy) SRCompletionHandler completionHandler;
@end

@implementation SRServerSentEventsTransport

- (instancetype)init {
    if (self = [super init]) {
        _serverSentEventsOperationQueue = [[NSOperationQueue alloc] init];
        [_serverSentEventsOperationQueue setMaxConcurrentOperationCount:1];
        _reconnectDelay = @2;
    }
    return self;
}

#pragma mark
#pragma mark SRClientTransportInterface

- (NSString *)name {
    return @"serverSentEvents";
}

- (BOOL)supportsKeepAlive {
    return YES;
}

- (void)negotiate:(id<SRConnectionInterface>)connection connectionData:(NSString *)connectionData completionHandler:(void (^)(SRNegotiationResponse * response, NSError *error))block {
    [super negotiate:connection connectionData:connectionData completionHandler:nil];
}

- (void)start:(id<SRConnectionInterface>)connection connectionData:(NSString *)connectionData completionHandler:(void (^)(id response, NSError *error))block {
    self.completionHandler = block;
    [self open:connection connectionData:connectionData];
}

- (void)send:(id<SRConnectionInterface>)connection data:(NSString *)data connectionData:(NSString *)connectionData completionHandler:(void (^)(id response, NSError *error))block {
    [super send:connection data:data connectionData:connectionData completionHandler:block];
}

- (void)abort:(id<SRConnectionInterface>)connection timeout:(NSNumber *)timeout connectionData:(NSString *)connectionData {
    [super abort:connection timeout:timeout connectionData:connectionData];
}

- (void)lostConnection:(id<SRConnectionInterface>)connection {
    [self.serverSentEventsOperationQueue cancelAllOperations];
}

#pragma mark -
#pragma mark SSE Transport

- (void)open:(id <SRConnectionInterface>)connection connectionData:(NSString *)connectionData {
    BOOL reconnecting = self.completionHandler == nil;
    
    NSString *url = (reconnecting) ? connection.url : [connection.url stringByAppendingString:@"connect"];
    url = [url stringByAppendingString:[self receiveQueryString:connection data:connectionData]];
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest setValue:@"text/event-stream" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"Keep-Alive" forHTTPHeaderField:@"Connection"];
    [urlRequest setTimeoutInterval:240];
    
    [connection prepareRequest:urlRequest];
    
    __block SREventSourceStreamReader *eventSource;
    SRHTTPRequestOperation *operation = [[SRHTTPRequestOperation alloc] initWithRequest:urlRequest];
    [operation setResponseSerializer:[AFJSONResponseSerializer serializer]];
    [operation setDidReceiveResponseBlock:^(AFHTTPRequestOperation *operation, NSHTTPURLResponse *response) {
        eventSource = [[SREventSourceStreamReader alloc] initWithStream:operation.outputStream];
        __weak __typeof(&*self)weakSelf = self;
        __weak __typeof(&*connection)weakConnection = connection;
        
        eventSource.opened = ^() {
            __strong __typeof(&*weakConnection)strongConnection = weakConnection;
            
            // This will noop if we're not in the reconnecting state
            if([strongConnection changeState:reconnecting toState:connected]) {
                // Raise the reconnect event if the connection comes back up
                [strongConnection didReconnect];
            }
        };
        eventSource.message = ^(SRServerSentEvent * sseEvent) {
            __strong __typeof(&*weakSelf)strongSelf = weakSelf;
            __strong __typeof(&*weakConnection)strongConnection = weakConnection;
            
            if([sseEvent.event isEqual:@"data"]) {
                NSString *data = [[NSString alloc] initWithData:sseEvent.data encoding:NSUTF8StringEncoding];
                if([data caseInsensitiveCompare:@"initialized"] == NSOrderedSame) {
                    return;
                }
                
                BOOL shouldReconnect = NO;
                BOOL disconnect = NO;
                [strongSelf processResponse:strongConnection response:data shouldReconnect:&shouldReconnect disconnected:&disconnect];
                if (strongSelf.completionHandler) {
                    strongSelf.completionHandler(nil,nil);
                    strongSelf.completionHandler = nil;
                }

                if(disconnect) {
                    SRLogServerSentEvents(@"disconnect received should disconnect");
                    _stop = YES;
                    [strongConnection disconnect];
                }
            }
        };
        eventSource.closed = ^(NSError *exception) {
            __strong __typeof(&*weakSelf)strongSelf = weakSelf;
            __strong __typeof(&*weakConnection)strongConnection = weakConnection;
            
            SRLogServerSentEvents(@"did close");
            
            if (exception != nil) {
                // Check if the request is aborted
                BOOL isRequestAborted = [SRExceptionHelper isRequestAborted:exception];

                if (!isRequestAborted) {
                    // Don't raise exceptions if the request was aborted (connection was stopped).
                    [strongConnection didReceiveError:exception];
                }
            }
            
            //requestDisposer.Dispose();
            //esCancellationRegistration.Dispose();
            //response.Dispose();
            
            if (_stop) {
                [strongSelf completeAbort];
            }
            else if ([strongSelf tryCompleteAbort]) {
            }
            else {
                [strongSelf reconnect:strongConnection data:connectionData];
            }
        };
        [eventSource start];
    }];
    
    __weak __typeof(&*self)weakSelf = self;
    __weak __typeof(&*connection)weakConnection = connection;
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        if (strongSelf.completionHandler) {
            strongSelf.completionHandler(nil, error);
            strongSelf.completionHandler = nil;
        } else if (!_stop && reconnecting) {
            [strongConnection didReceiveError:error];
            [strongSelf reconnect:strongConnection data:connectionData];
        }
    }];
    [self.serverSentEventsOperationQueue addOperation:operation];
}

- (void)reconnect:(id <SRConnectionInterface>)connection data:(NSString *)data {
    __weak __typeof(&*self)weakSelf = self;
    __weak __typeof(&*connection)weakConnection = connection;
    [[NSBlockOperation blockOperationWithBlock:^{
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        
        if (connection.state != disconnected && [SRConnection ensureReconnecting:strongConnection]) {
            SRLogServerSentEvents(@"reconnecting");
            [strongSelf open:strongConnection connectionData:data];
            [strongSelf.serverSentEventsOperationQueue cancelAllOperations];
        }
        
    }] performSelector:@selector(start) withObject:nil afterDelay:[self.reconnectDelay integerValue]];
}

- (BOOL)isConnectionReconnecting:(id<SRConnectionInterface>)connection {
    return connection.state == reconnecting;
}

@end
