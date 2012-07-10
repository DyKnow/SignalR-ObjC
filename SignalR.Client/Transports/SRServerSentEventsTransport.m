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
#import "SRSignalRConfig.h"
#import "SRSseEvent.h"
#import "SRThreadSafeInvoker.h"

#import "NSTimer+Blocks.h"

@interface SRServerSentEventsTransport ()

@property (assign, nonatomic, readwrite) NSInteger reconnectDelay;

- (void)openConnection:(SRConnection *)connection data:(NSString *)data initializeCallback:(void (^)(void))initializeCallback errorCallback:(void (^)(SRErrorByReferenceBlock))errorCallback;

@end

@implementation SRServerSentEventsTransport

@synthesize connectionTimeout = _connectionTimeout;
@synthesize reconnectDelay = _reconnectDelay;

static NSString * const kTransportName = @"serverSentEvents";
static NSString * const kEventSourceKey = @"eventSourceStream";

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
        _connectionTimeout = 2;
        _reconnectDelay = 2;
    }
    return self;
}


- (void)onStart:(SRConnection *)connection data:(NSString *)data initializeCallback:(void (^)(void))initializeCallback errorCallback:(void (^)(SRErrorByReferenceBlock))errorCallback
{
    [self openConnection:connection data:data initializeCallback:initializeCallback errorCallback:errorCallback];
}

- (void)reconnect:(SRConnection *)connection data:(NSString *)data
{
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_HTTP_BASED_TRANSPORT
    SR_DEBUG_LOG(@"[SERVER_SENT_EVENTS] reconnecting");
#endif   
    
    //Wait for a bit before reconnecting
    [NSTimer scheduledTimerWithTimeInterval:_reconnectDelay block:^
    {
        if (connection.state == reconnecting ||
            [connection changeState:connected toState:reconnecting])
        {
            //Now attempt a reconnect
            [self openConnection:connection data:data initializeCallback:nil errorCallback:nil];
        }
    } repeats:NO];
}

- (void)openConnection:(SRConnection *)connection data:(NSString *)data initializeCallback:(void (^)(void))initializeCallback errorCallback:(void (^)(SRErrorByReferenceBlock))errorCallback
{
    // If we're reconnecting add /connect to the url
    BOOL _reconnecting = initializeCallback == nil;
    SRThreadSafeInvoker *callbackInvoker = [[SRThreadSafeInvoker alloc] init];
    
    NSString *url = [(_reconnecting ? connection.url : [connection.url stringByAppendingString:kConnectEndPoint]) stringByAppendingFormat:@"%@",[self getReceiveQueryString:connection data:data]];

    [self.httpClient getAsync:url requestPreparer:^(id<SRRequest> request)
    {
        [self prepareRequest:request forConnection:connection];

        [request setAccept:@"text/event-stream"];
    }
    continueWith:^(id<SRResponse> response)
    {
        BOOL isFaulted = (response.error || 
                          [response.string isEqualToString:@""] ||
                          [response.string isEqualToString:@"null"]);
        
        if (isFaulted)
        {
            if(![SRExceptionHelper isRequestAborted:response.error])
            {                        
                if (errorCallback != nil)
                {
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_HTTP_BASED_TRANSPORT
                    SR_DEBUG_LOG(@"[SERVER_SENT_EVENTS] isFaulted will report to errorCallback");
#endif
                    [callbackInvoker invoke:^(callback cb, NSError *ex) 
                    {
                        SRErrorByReferenceBlock errorBlock = ^(NSError ** error)
                        {
                            if(error)
                            {
                                *error = ex;
                            }
                        };
                        cb(errorBlock);
                    } 
                    withCallback:errorCallback 
                    withObject:response.error];
                }
                else if(_reconnecting)
                {
                    // Only raise the error event if we failed to reconnect
                    [connection didReceiveError:response.error];
                    
                    [self reconnect:connection data:data];
                }
            }
        }
        else
        {
            SREventSourceStreamReader *eventSource = [[SREventSourceStreamReader alloc] initWithStream:response.stream];
            __unsafe_unretained SRServerSentEventsTransport *weakTransport = self;
            __unsafe_unretained SRThreadSafeInvoker *weakCallbackInvoker = callbackInvoker;
            __unsafe_unretained SRConnection *weakConnection = connection;
            __unsafe_unretained NSString *weakData = data;
            typedef void (^SRInitializedCallback)(void);
            __block SRInitializedCallback weakInitializedCallback = initializeCallback;
            __block BOOL retry = YES;
            
            [connection.items setObject:eventSource forKey:kEventSourceKey];
            
            eventSource.opened = ^()
            {
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_HTTP_BASED_TRANSPORT
                SR_DEBUG_LOG(@"[SERVER_SENT_EVENTS] did initialize");
#endif
                
                if (weakInitializedCallback != nil)
                {
                    [weakCallbackInvoker invoke:weakInitializedCallback];
                    weakInitializedCallback = nil;
                }
                
                if(_reconnecting && [weakConnection changeState:reconnecting toState:connected])
                {
                    // Raise the reconnect event if the connection comes back up
                    [weakConnection didReconnect];
                }
            };
            
            eventSource.message = ^(SRSseEvent * sseEvent)
            {
                if(sseEvent.type == Data)
                {
                    if([sseEvent.data caseInsensitiveCompare:@"initialized"] == NSOrderedSame)
                    {
                        return;
                    }
                    
                    BOOL timedOut = NO;
                    BOOL disconnect = NO;
                    [weakTransport processResponse:weakConnection response:sseEvent.data timedOut:&timedOut disconnected:&disconnect];
                    
                    if(disconnect)
                    {
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_HTTP_BASED_TRANSPORT
                        SR_DEBUG_LOG(@"[SERVER_SENT_EVENTS] disconnectReceived should disconnect");
#endif
                        retry = NO;
                    }
                }
            };
            
            eventSource.closed = ^(NSError * error)
            {
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_HTTP_BASED_TRANSPORT
                SR_DEBUG_LOG(@"[SERVER_SENT_EVENTS] did close");
#endif
                if (error != nil && ![SRExceptionHelper isRequestAborted:error])
                {
                    // Don't raise exceptions if the request was aborted (connection was stopped).
                    [weakConnection didReceiveError:error];
                }
                
                if(retry)
                {
                    [weakTransport reconnect:weakConnection data:weakData];
                }
                else
                {
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_HTTP_BASED_TRANSPORT
                    SR_DEBUG_LOG(@"[SERVER_SENT_EVENTS] will abort connection");
#endif
                    [weakConnection stop];
                }
            };
            
            [eventSource start];
        }
    }];
    
    if (errorCallback != nil)
    {
        [NSTimer scheduledTimerWithTimeInterval:_connectionTimeout block:
        ^{
            [callbackInvoker invoke:^(callback cb, SRConnection *conn) 
            {
                // Stop the connection
                [self stop:conn];
                
                SRErrorByReferenceBlock errorBlock = ^(NSError ** error)
                {
                    if(error)
                    {
                        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
                        [userInfo setObject:NSInternalInconsistencyException forKey:NSLocalizedFailureReasonErrorKey];
                        [userInfo setObject:[NSString stringWithFormat:NSLocalizedString(@"Transport took longer than %d to connect",@""),_connectionTimeout] forKey:NSLocalizedDescriptionKey];
                        *error = [NSError errorWithDomain:[NSString stringWithFormat:NSLocalizedString(@"com.SignalR-ObjC.%@",@""),NSStringFromClass([self class])] 
                                                    code:NSURLErrorTimedOut 
                                                userInfo:userInfo];
                    }
                };
                cb(errorBlock);
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_HTTP_BASED_TRANSPORT
                SR_DEBUG_LOG(@"[SERVER_SENT_EVENTS] did call errorCallBack with timeout error");
#endif
            } 
            withCallback:errorCallback 
            withObject:connection];
        } repeats:NO];
    }
}

- (void)onBeforeAbort:(SRConnection *)connection
{
    SREventSourceStreamReader *eventSourceStream = [connection.items objectForKey:kEventSourceKey];
    if (eventSourceStream != nil)
    {
        [eventSourceStream close];
        eventSourceStream = nil;
    }
    [super onBeforeAbort:connection];
}

- (void)dealloc
{
    _connectionTimeout = 0;
    _reconnectDelay = 0;
}

@end