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

#import "SRServerSentEventsTransport.h"
#import "SRConnection.h"
#import "SRDefaultHttpClient.h"
#import "SREventSourceStreamReader.h"
#import "SRExceptionHelper.h"
#import "SRLog.h"
#import "SRSseEvent.h"
#import "SRThreadSafeInvoker.h"

@interface SRServerSentEventsTransport ()

- (void)openConnection:(SRConnection *)connection data:(NSString *)data initializeCallback:(void (^)(void))initializeCallback errorCallback:(void (^)(SRErrorByReferenceBlock))errorCallback;

@end

@implementation SRServerSentEventsTransport

static NSString * const kTransportName = @"serverSentEvents";

- (id)init {
    if(self = [self initWithHttpClient:[[SRDefaultHttpClient alloc] init]]) {
    }
    return self;
}

- (id)initWithHttpClient:(id<SRHttpClient>)httpClient {
    if (self = [super initWithHttpClient:httpClient transport:kTransportName]) {
        _connectionTimeout = 2;
        _reconnectDelay = 2;
    }
    return self;
}

- (void)onStart:(SRConnection *)connection data:(NSString *)data initializeCallback:(void (^)(void))initializeCallback errorCallback:(void (^)(SRErrorByReferenceBlock))errorCallback {
    [self openConnection:connection data:data initializeCallback:initializeCallback errorCallback:errorCallback];
}

- (void)reconnect:(SRConnection *)connection data:(NSString *)data {
    SRLogServerSentEvents(@"reconnecting");
    
    //Wait for a bit before reconnecting
    [[NSBlockOperation blockOperationWithBlock:^{
        #warning make sure request is not cancelled
        //if (!disconnectToken.IsCancellationRequested && [connection ensureReconnecting]) {
        if ([connection ensureReconnecting]) {
            //Now attempt a reconnect
            [self openConnection:connection data:data initializeCallback:nil errorCallback:nil];
        }
    }] performSelector:@selector(start) withObject:nil afterDelay:_reconnectDelay];
}

- (void)openConnection:(SRConnection *)connection data:(NSString *)data initializeCallback:(void (^)(void))initializeCallback errorCallback:(void (^)(SRErrorByReferenceBlock))errorCallback
{
    // If we're reconnecting add /connect to the url
    BOOL _reconnecting = initializeCallback == nil;
    SRThreadSafeInvoker *callbackInvoker = [[SRThreadSafeInvoker alloc] init];
    
    NSString *url = [(_reconnecting ? connection.url : [connection.url stringByAppendingString:@"connect"]) stringByAppendingFormat:@"%@",[self getReceiveQueryString:connection data:data]];
    __block id <SRRequest> request = nil;
    __block SREventSourceStreamReader *eventSource;

    [self.httpClient getAsync:url requestPreparer:^(id<SRRequest> req) {
        request = req;
        [connection prepareRequest:request];

        [request setAccept:@"text/event-stream"];
    } continueWith:^(id<SRResponse> response) {
        BOOL isFaulted = (response.error || 
                          [response.string isEqualToString:@""] ||
                          [response.string isEqualToString:@"null"]);
        
        if (isFaulted) {
            NSError *exception = response.error;
            if(![SRExceptionHelper isRequestAborted:exception]) {                        
                if (errorCallback != nil) {
                    SRLogServerSentEvents(@"isFaulted will report to errorCallback");

                    [callbackInvoker invoke:^(callback cb, NSError *ex) {
                        SRErrorByReferenceBlock errorBlock = ^(NSError ** error) {
                            if(error) {
                                *error = ex;
                            }
                        };
                        cb(errorBlock);
                    } 
                    withCallback:errorCallback 
                    withObject:exception];
                } else if(_reconnecting) {
                    // Only raise the error event if we failed to reconnect
                    [connection didReceiveError:exception];
                    
                    [self reconnect:connection data:data];
                }
            }
        } else {
            eventSource = [[SREventSourceStreamReader alloc] initWithStream:response.stream];
            __weak __typeof(&*self)weakSelf = self;
            __weak __typeof(&*connection)weakConnection = connection;
            __weak __typeof(&*response)weakResponse = response;
            __weak __typeof(&*data)weakData = data;
            __weak __typeof(&*callbackInvoker)weakCallbackInvoker = callbackInvoker;

            typedef void (^SRInitializedCallback)(void);
            __block SRInitializedCallback weakInitializedCallback = initializeCallback;
            __block BOOL retry = YES;
            
#warning TODO: if disconnected close the event source
            /*var eventSourceCancellationRegistration = disconnectToken.SafeRegister(es => {
                retry = false;
                es.Close();
            }, eventSource);*/

            eventSource.opened = ^() {
                __strong __typeof(&*weakConnection)strongConnection = weakConnection;
                __strong __typeof(&*weakCallbackInvoker)strongCallbackInvoker = weakCallbackInvoker;

                SRLogServerSentEvents(@"did initialize");

                if (!_reconnecting) {
                    if (weakInitializedCallback != nil) {
                        [strongCallbackInvoker invoke:weakInitializedCallback];
                        weakInitializedCallback = nil;
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

                        retry = NO;
                        [connection disconnect];
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
                
                // Skip reconnect attempt for aborted requests
                if (!isRequestAborted && retry)
                {
                    [strongSelf reconnect:strongConnection data:strongData];
                }
            };
            
            eventSource.disabled = ^() {
                __strong __typeof(&*weakResponse)strongResponse = weakResponse;
                //requestDisposer.Dispose();
                //esCancellationRegistration.Dispose();
                [strongResponse close];
            };
            
            [eventSource start];
        }
    }];
    
#warning TODO: Receive Notification when a disconnect occurs and stop the pending request
    /*var requestCancellationRegistration = disconnectToken.SafeRegister(req => {
        if (req != null) {
            // This will no-op if the request is already finished.
            req.Abort();
        }
        
        if (errorCallback != null) {
            callbackInvoker.Invoke((cb, token) => {
                cb(new OperationCanceledException(Resources.Error_ConnectionCancelled, token));
            }, errorCallback, disconnectToken);
        }
    }, request);
    
    requestDisposer.Set(requestCancellationRegistration);*/
    
    if (errorCallback != nil) {
        [[NSBlockOperation blockOperationWithBlock:^{
            [callbackInvoker invoke:^(callback cb, SRConnection *conn) {
                [connection disconnect];
                
                SRErrorByReferenceBlock errorBlock = ^(NSError ** error) {
                    if(error) {
                        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
                        userInfo[NSLocalizedFailureReasonErrorKey] = NSInternalInconsistencyException;
                        userInfo[NSLocalizedDescriptionKey] = [NSString stringWithFormat:NSLocalizedString(@"Transport took longer than %d to connect",@""),_connectionTimeout];
                        *error = [NSError errorWithDomain:[NSString stringWithFormat:NSLocalizedString(@"com.SignalR-ObjC.%@",@""),NSStringFromClass([self class])]
                                                     code:NSURLErrorTimedOut
                                                 userInfo:userInfo];
                    }
                };
                cb(errorBlock);
                SRLogServerSentEvents(@"did call errorCallBack with timeout error");
            }
            withCallback:errorCallback
            withObject:connection];
        }] performSelector:@selector(start) withObject:nil afterDelay:_connectionTimeout];
    }
}

- (void)dealloc {
    _connectionTimeout = 0;
    _reconnectDelay = 0;
}

@end
