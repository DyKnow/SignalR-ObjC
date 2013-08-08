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
#import "SRSseEvent.h"
#import "SRConnectionExtensions.h"
#import "SRLog.h"
#import "SRChunkBuffer.h"

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

typedef void (^SRServerSentEventsInitializedBlock)(void);
typedef void (^SRServerSentEventsErrorBlock)(NSError *);

@interface SRServerSentEventsTransport ()

@property (strong, nonatomic, readwrite) NSOperationQueue *serverSentEventsOperationQueue;
@property (copy) SRServerSentEventsInitializedBlock initializeCallback;
@property (copy) SRServerSentEventsErrorBlock errorCallback;

@end

@implementation SRServerSentEventsTransport

static NSString * const kTransportName = @"serverSentEvents";

- (instancetype)init {
    if (self = [super init]) {
        _serverSentEventsOperationQueue = [[NSOperationQueue alloc] init];
        [_serverSentEventsOperationQueue setMaxConcurrentOperationCount:1];
        _connectionTimeout = @5;
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
    [self openConnection:connection data:data];
}

- (void)openConnection:(id <SRConnectionInterface>)connection data:(NSString *)data {
    BOOL _reconnecting = self.initializeCallback == nil;
    
    NSString *url = (_reconnecting) ? connection.url : [connection.url stringByAppendingString:@"connect"];
    url = [url stringByAppendingString:[self receiveQueryString:connection data:data]];
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest setValue:@"text/event-stream" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"Keep-Alive" forHTTPHeaderField:@"Connection"];
    [urlRequest setTimeoutInterval:240];
    
    [connection prepareRequest:urlRequest];
    
    __block SREventSourceStreamReader *eventSource;
    SRHTTPRequestOperation *operation = [[SRHTTPRequestOperation alloc] initWithRequest:urlRequest];
    [operation setDidReceiveResponseBlock:^(AFHTTPRequestOperation *operation, NSHTTPURLResponse *response) {
        eventSource = [[SREventSourceStreamReader alloc] initWithStream:operation.outputStream];
        __weak __typeof(&*self)weakSelf = self;
        __weak __typeof(&*operation)weakOperation = operation;
        __weak __typeof(&*connection)weakConnection = connection;
        __weak __typeof(&*data)weakData = data;
        
        __block BOOL stop = NO;
        
#warning TODO: handle connection disconnect event, abort any pending requests and set stop to YES
        
        eventSource.opened = ^() {
            __strong __typeof(&*weakSelf)strongSelf = weakSelf;
            __strong __typeof(&*weakConnection)strongConnection = weakConnection;
            
            SRLogServerSentEvents(@"did initialize");
            
            if (!_reconnecting) {
                if (strongSelf.initializeCallback != nil) {
                    strongSelf.initializeCallback();
                    strongSelf.initializeCallback = nil;
                }
            } else if([strongConnection changeState:reconnecting toState:connected]) {
                // Raise the reconnect event if the connection comes back up
                [strongConnection didReconnect];
            }
        };
        eventSource.message = ^(SRSseEvent * sseEvent) {
            __strong __typeof(&*weakSelf)strongSelf = weakSelf;
            __strong __typeof(&*weakConnection)strongConnection = weakConnection;
            
            if(sseEvent.eventType == Data) {
                if([sseEvent.data caseInsensitiveCompare:@"initialized"] == NSOrderedSame) {
                    return;
                }
                
                BOOL timedOut = NO;
                BOOL disconnect = NO;
                [strongSelf processResponse:strongConnection response:sseEvent.data timedOut:&timedOut disconnected:&disconnect];
                
                if(disconnect) {
                    SRLogServerSentEvents(@"disconnect received should disconnect");
                    stop = YES;
                    [strongConnection disconnect];
                }
            }
        };
        eventSource.closed = ^(NSError *exception) {
            __strong __typeof(&*weakSelf)strongSelf = weakSelf;
            __strong __typeof(&*weakConnection)strongConnection = weakConnection;
            __strong __typeof(&*weakData)strongData = weakData;
            
            SRLogServerSentEvents(@"did close");
            BOOL isRequestAborted = NO;
            
            if (exception != nil) {
                // Check if the request is aborted
                isRequestAborted = [SRExceptionHelper isRequestAborted:exception];
                
                if (!isRequestAborted) {
                    // Don't raise exceptions if the request was aborted (connection was stopped).
                    [strongConnection didReceiveError:exception];
                }
            }
            
#warning TODO: dispose of handle connection disconnect block defined above
            
            if (stop)
            {
                [strongSelf completeAbort];
            }
            else if ([strongSelf tryCompleteAbort])
            {
            }
            else
            {
                [strongSelf reconnect:strongConnection data:strongData];
            }
        };
        [eventSource start];
    }];
    [operation start];
    //[self.serverSentEventsOperationQueue addOperation:operation];
    
#warning TODO: register disconnect handler
}

- (void)reconnect:(id <SRConnectionInterface>)connection data:(NSString *)data {
    SRLogServerSentEvents(@"reconnecting");
    if (connection.state != disconnected && [SRConnection ensureReconnecting:connection]) {
        //Now attempt a reconnect
        [self setInitializeCallback:nil];
        [self setErrorCallback:nil];
        [self openConnection:connection data:data];
    }
}

- (void)send:(id <SRConnectionInterface>)connection data:(NSString *)data completionHandler:(void (^)(id response))block {
    [super send:connection data:data completionHandler:block];
}

- (void)lostConnection:(id<SRConnectionInterface>)connection {
#warning TODO: abort any pending requests
}

- (void)abort:(id <SRConnectionInterface>)connection timeout:(NSNumber *)timeout{
    [super abort:connection timeout:timeout];
}

@end
