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
#import "SRSignalRConfig.h"

#import "SRDefaultHttpClient.h"
#import "SRConnection.h"
#import "NSTimer+Blocks.h"

typedef void (^onInitialized)(void);

@interface SRLongPollingTransport()

@property (assign, nonatomic, readwrite) NSInteger errorDelay;

- (void)pollingLoop:(SRConnection *)connection data:(NSString *)data initializeCallback:(void (^)(void))initializeCallback errorCallback:(void (^)(SRErrorByReferenceBlock))errorCallback;
- (void)pollingLoop:(SRConnection *)connection data:(NSString *)data initializeCallback:(void (^)(void))initializeCallback errorCallback:(void (^)(SRErrorByReferenceBlock))errorCallback raiseReconnect:(BOOL)raiseReconnect;
- (void)fireReconnected:(SRConnection *)connection reconnectCancelled:(BOOL)cancelled reconnectedFired:(int *)reconnectedFired;

#define kTransportName @"longPolling"

@end

@implementation SRLongPollingTransport

@synthesize reconnectDelay = _reconnectDelay;
@synthesize errorDelay = _errorDelay;

- (id)init
{
    if(self = [self initWithHttpClient:[[SRDefaultHttpClient alloc] init]])
    {
    }
    return self;
}

- (id)initWithHttpClient:(id<SRHttpClient>)httpClient
{
    if (self = [super initWithHttpClient:httpClient transport:kTransportName])
    {
        _reconnectDelay = 5;
        _errorDelay = 2;
    }
    return self;
}

- (void)onStart:(SRConnection *)connection data:(NSString *)data initializeCallback:(void (^)(void))initializeCallback errorCallback:(void (^)(SRErrorByReferenceBlock))errorCallback;
{
    [self pollingLoop:connection data:data initializeCallback:initializeCallback errorCallback:errorCallback];
}

- (void)pollingLoop:(SRConnection *)connection data:(NSString *)data initializeCallback:(void (^)(void))initializeCallback errorCallback:(void (^)(SRErrorByReferenceBlock))errorCallback
{    
    [self pollingLoop:connection data:data initializeCallback:initializeCallback errorCallback:errorCallback raiseReconnect:NO];
}

- (void)pollingLoop:(SRConnection *)connection data:(NSString *)data initializeCallback:(void (^)(void))initializeCallback errorCallback:(void (^)(SRErrorByReferenceBlock))errorCallback raiseReconnect:(BOOL)raiseReconnect
{ 
    NSString *url = connection.url;
    __block BOOL reconnectCancelled = NO;
    __block NSInteger reconnectFired = 0;
    
    // This is only necessary for the initial request where initializeCallback and errorCallback are non-null
    __block int callbackFired = 0;
    
    if(connection.messageId == nil)
    {
        url = [url stringByAppendingString:kConnectEndPoint];
    }
    else if (raiseReconnect)
    {
        url = [url stringByAppendingString:kReconnectEndPoint];
    }
    
    url = [url stringByAppendingFormat:@"%@",[self getReceiveQueryString:connection data:data]];
    
    [self.httpClient postAsync:url requestPreparer:^(id request)
    {
        [self prepareRequest:request forConnection:connection];
    } 
    continueWith:^(id response)
    {
#if DEBUG_LONG_POLLING || DEBUG_HTTP_BASED_TRANSPORT
        SR_DEBUG_LOG(@"[LONG_POLLING] did receive response %@",response);
#endif
        // Clear the pending request
        [connection.items removeObjectForKey:kHttpRequestKey];

        BOOL shouldRaiseReconnect = NO;
        BOOL disconnectedReceived = NO;
        
        BOOL isFaulted = ([response isKindOfClass:[NSError class]] || 
                          [response isEqualToString:@""] || response == nil ||
                          [response isEqualToString:@"null"]);
        @try 
        {
            if([response isKindOfClass:[NSString class]])
            {
                if(!isFaulted)
                {
                    if(raiseReconnect)
                    {
                        // If the timeout for the receonnect hasn't fired as yet just fire the 
                        // Event here before any incoming messages are processed
                        [self fireReconnected:connection reconnectCancelled:reconnectCancelled reconnectedFired:&reconnectFired];
                    }
                    
                    [self processResponse:connection response:response timedOut:&shouldRaiseReconnect disconnected:&disconnectedReceived];
                }
            }
        }
        @finally 
        {
            if(disconnectedReceived)
            {
#if DEBUG_LONG_POLLING || DEBUG_HTTP_BASED_TRANSPORT
                SR_DEBUG_LOG(@"[LONG_POLLING] did disconnect");
#endif
                [connection stop];
            }
            else
            {
                BOOL requestAborted = NO;
                
                if (isFaulted)
                {
#if DEBUG_LONG_POLLING || DEBUG_HTTP_BASED_TRANSPORT
                    SR_DEBUG_LOG(@"[LONG_POLLING] isFaulted");
#endif
                    // Cancel the previous reconnect event
                    reconnectCancelled = YES;
                    
                    // Raise the reconnect event if we successfully reconect after failing
                    shouldRaiseReconnect = YES;
                    
                    if([response isKindOfClass:[NSError class]])
                    {
                        // If the error callback isn't null then raise it and don't continue polling
                        if (errorCallback && callbackFired == 0)
                        {
#if DEBUG_LONG_POLLING || DEBUG_HTTP_BASED_TRANSPORT
                            SR_DEBUG_LOG(@"[LONG_POLLING] will report error to errorCallback");
#endif
                            callbackFired = 1;
                            
                            [connection didReceiveError:response];
                            
                            //Call the callback
                            SRErrorByReferenceBlock errorBlock = ^(NSError ** error)
                            {
                                *error = response;
                            };
                            errorCallback(errorBlock);
                        }
                        else
                        {
                            //Figure out if the request is aborted
                            requestAborted = [self isRequestAborted:response];
                            
                            //Sometimes a connection might have been closed by the server before we get to write anything
                            //So just try again and don't raise an error
                            if(!requestAborted)
                            {
                                //Raise Error
                                [connection didReceiveError:response];
                                
                                //If the connection is still active after raising the error wait 2 seconds 
                                //before polling again so we arent hammering the server
                                
#if DEBUG_LONG_POLLING || DEBUG_HTTP_BASED_TRANSPORT
                                SR_DEBUG_LOG(@"[LONG_POLLING] will poll again in %d seconds",_errorDelay);
#endif
                                [NSTimer scheduledTimerWithTimeInterval:_errorDelay block:
                                 ^{
                                     if (connection.isActive)
                                     {
                                         [self pollingLoop:connection data:data initializeCallback:nil errorCallback:nil raiseReconnect:shouldRaiseReconnect];
                                     }
                                 } repeats:NO];    
                            }
                        }
                    }
                }
                else
                {
                    if (connection.isActive)
                    {
#if DEBUG_LONG_POLLING || DEBUG_HTTP_BASED_TRANSPORT
                        SR_DEBUG_LOG(@"[LONG_POLLING] will poll again immediately");
#endif
                        [self pollingLoop:connection data:data initializeCallback:nil errorCallback:nil raiseReconnect:shouldRaiseReconnect];
                    }
                }
            }
        }
    }];
    
    if (initializeCallback != nil && callbackFired == 0)
    {
#if DEBUG_LONG_POLLING || DEBUG_HTTP_BASED_TRANSPORT
        SR_DEBUG_LOG(@"[LONG_POLLING] connection is initialized");
#endif
        callbackFired = 1;
        // Only set this the first time
        initializeCallback();
    }
    
    if (raiseReconnect)
    {
        [NSTimer scheduledTimerWithTimeInterval:_reconnectDelay block:^
        {
            [self fireReconnected:connection reconnectCancelled:reconnectCancelled reconnectedFired:&reconnectFired];
        } repeats:NO];
    }
}

- (void)fireReconnected:(SRConnection *)connection reconnectCancelled:(BOOL)cancelled reconnectedFired:(int *)reconnectedFired
{
    if(!cancelled)
    {
#if DEBUG_LONG_POLLING || DEBUG_HTTP_BASED_TRANSPORT
        SR_DEBUG_LOG(@"[LONG_POLLING] did fire reconnected");
#endif
        *reconnectedFired = 1;
        [connection didReconnect];
    }
}

- (void)dealloc
{
    
}

@end
