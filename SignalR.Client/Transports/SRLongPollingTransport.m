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

#import "SRLongPollingTransport.h"
#import "SRConnection.h"
#import "SRDefaultHttpClient.h"
#import "SRExceptionHelper.h"
#import "SRLog.h"
#import "SRThreadSafeInvoker.h"

typedef void (^onInitialized)(void);

@interface SRLongPollingTransport()

- (void)pollingLoop:(SRConnection *)connection data:(NSString *)data initializeCallback:(void (^)(void))initializeCallback errorCallback:(void (^)(SRErrorByReferenceBlock))errorCallback;
- (void)pollingLoop:(SRConnection *)connection data:(NSString *)data initializeCallback:(void (^)(void))initializeCallback errorCallback:(void (^)(SRErrorByReferenceBlock))errorCallback raiseReconnect:(BOOL)raiseReconnect;
- (void)fireReconnected:(SRConnection *)connection;

@end

@implementation SRLongPollingTransport

static NSString * const kTransportName = @"longPolling";

- (id)init {
    if(self = [self initWithHttpClient:[[SRDefaultHttpClient alloc] init]]) {
    }
    return self;
}

- (id)initWithHttpClient:(id<SRHttpClient>)httpClient {
    if (self = [super initWithHttpClient:httpClient transport:kTransportName]) {
        _reconnectDelay = 5;
        _errorDelay = 2;
        _connectDelay = 2;
    }
    return self;
}

- (void)onStart:(SRConnection *)connection data:(NSString *)data initializeCallback:(void (^)(void))initializeCallback errorCallback:(void (^)(SRErrorByReferenceBlock))errorCallback; {
    [self pollingLoop:connection data:data initializeCallback:initializeCallback errorCallback:errorCallback];
}

- (void)pollingLoop:(SRConnection *)connection data:(NSString *)data initializeCallback:(void (^)(void))initializeCallback errorCallback:(void (^)(SRErrorByReferenceBlock))errorCallback {    
    [self pollingLoop:connection data:data initializeCallback:initializeCallback errorCallback:errorCallback raiseReconnect:NO];
}

- (void)pollingLoop:(SRConnection *)connection data:(NSString *)data initializeCallback:(void (^)(void))initializeCallback errorCallback:(void (^)(SRErrorByReferenceBlock))errorCallback raiseReconnect:(BOOL)raiseReconnect { 
    NSString *url = connection.url;
    
    __block id <SRRequest> request = nil;
    SRThreadSafeInvoker *reconnectInvoker = [[SRThreadSafeInvoker alloc] init];
    SRThreadSafeInvoker *callbackInvoker = [[SRThreadSafeInvoker alloc] init];

    if(connection.messageId == nil) {
        url = [url stringByAppendingString:@"connect"];
    } else if (raiseReconnect) {
        url = [url stringByAppendingString:@"reconnect"];
        
#warning make sure request is not cancelled
        //if (disconnectToken.IsCancellationRequested || ![connection ensureReconnecting]) {
        if (![connection ensureReconnecting]) {
            return;
        }
    }
    
    url = [url stringByAppendingString:[self getReceiveQueryString:connection data:data]];
    
    [self.httpClient postAsync:url requestPreparer:^(id<SRRequest> req) {
        request = req;
        [connection prepareRequest:request];
    } continueWith:^(id<SRResponse> response) {
        SRLogLongPolling(@"did receive response %@",response);
        
        BOOL shouldRaiseReconnect = NO;
        BOOL disconnectedReceived = NO;
        
        BOOL isFaulted = (response.error || 
                          [response.string isEqualToString:@""] ||
                          [response.string isEqualToString:@"null"]);
        @try {
            if(!isFaulted) {
                if(raiseReconnect) {
                    // If the timeout for the receonnect hasn't fired as yet just fire the 
                    // Event here before any incoming messages are processed
                    [reconnectInvoker invoke:^(SRConnection *conn) { [self fireReconnected:conn]; } withObject:connection];
                }
                
                if (initializeCallback != nil) {
                    // If the timeout for connect hasn't fired as yet then just fire
                    // the event before any incoming messages are processed
                    [callbackInvoker invoke:initializeCallback];
                }
                
                // Get the response
                NSString *raw = response.string;
                
                [self processResponse:connection response:raw timedOut:&shouldRaiseReconnect disconnected:&disconnectedReceived];
            }
        } @finally {
            if(disconnectedReceived) {
                SRLogLongPolling(@"did disconnect");

                [connection disconnect];
            } else {
                BOOL requestAborted = NO;
                
                if (isFaulted) {
                    SRLogLongPolling(@"isFaulted");

                    [reconnectInvoker invoke];
                    
                    // Raise the reconnect event if we successfully reconect after failing
                    shouldRaiseReconnect = YES;
                    
                    // Get the underlying exception
                    NSError *exception = response.error;
                    
                    if(exception) {
                        // If the error callback isn't null then raise it and don't continue polling
                        if (errorCallback != nil) {
                            SRLogLongPolling(@"will report error to errorCallback");

                            //Call the callback
                            [callbackInvoker invoke:^(callback cb, NSError *ex) {
                                SRErrorByReferenceBlock errorBlock = ^(NSError ** error){
                                    if(error){
                                        *error = ex;
                                    }
                                };
                                cb(errorBlock);
                            } 
                            withCallback:errorCallback 
                            withObject:exception];
                        } else {
                            //Figure out if the request is aborted
                            requestAborted = [SRExceptionHelper isRequestAborted:exception];
                            
                            //Sometimes a connection might have been closed by the server before we get to write anything
                            //So just try again and don't raise an error
                            if(!requestAborted) {
                                //Raise Error
                                [connection didReceiveError:exception];
                                
                                //If the connection is still active after raising the error wait 2 seconds 
                                //before polling again so we arent hammering the server
                                
                                SRLogLongPolling(@"will poll again in %d seconds",_errorDelay);

                                [[NSBlockOperation blockOperationWithBlock:^{
                                    #warning make sure request is not cancelled
                                    //if (!disconnectToken.IsCancellationRequested) {
                                    if (connection.state != disconnected) {
                                        [self pollingLoop:connection data:data initializeCallback:nil errorCallback:nil raiseReconnect:shouldRaiseReconnect];
                                    }
                                }] performSelector:@selector(start) withObject:nil afterDelay:_errorDelay];
                            }
                        }
                    }
                } else {
                    #warning make sure request is not cancelled
                    //if (!disconnectToken.IsCancellationRequested) {
                    if (connection.state != disconnected) {
                        SRLogLongPolling(@"will poll again immediately");
                        
                        [self pollingLoop:connection data:data initializeCallback:nil errorCallback:nil raiseReconnect:shouldRaiseReconnect];
                    }
                }
            }
        }
    }];
    
#warning TODO: Receive Notification when a disconnect occurs and stop the pending request
    /*var requestCancellationRegistration = disconnectToken.SafeRegister(req => {
        if (req != null) {
            // This will no-op if the request is already finished.
            req.Abort();
        }
        
        // Prevent the connection state from switching to the reconnected state.
        reconnectInvoker.Invoke();
        
        if (errorCallback != null) {
            callbackInvoker.Invoke((cb, token) => {
                cb(new OperationCanceledException(Resources.Error_ConnectionCancelled, token));
            }, errorCallback, disconnectToken);
        }
    }, request);
    
    requestDisposer.Set(requestCancellationRegistration);*/
    
    if (initializeCallback != nil) {
        SRLogLongPolling(@"connection is initialized");

        [[NSBlockOperation blockOperationWithBlock:^{
            [callbackInvoker invoke:initializeCallback];
        }] performSelector:@selector(start) withObject:nil afterDelay:_connectDelay];
    }
    
    if (raiseReconnect){
        [[NSBlockOperation blockOperationWithBlock:^{
            [reconnectInvoker invoke:^(SRConnection *conn) { [self fireReconnected:conn]; } withObject:connection];
        }] performSelector:@selector(start) withObject:nil afterDelay:_reconnectDelay];
    }
}

- (void)fireReconnected:(SRConnection *)connection {
    if ([connection changeState:reconnecting toState:connected]) {
        SRLogLongPolling(@"did fire reconnected");

        [connection didReconnect];
    }
}

- (void)dealloc
{
    
}

@end
