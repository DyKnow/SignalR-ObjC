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
#import "SRConnectionExtensions.h"
#import "SRDefaultHttpClient.h"
#import "SREventSourceStreamReader.h"
#import "SRExceptionHelper.h"
#import "SRSignalRConfig.h"
#import "SRSseEvent.h"

#import "NSTimer+Blocks.h"

@interface SRServerSentEventsTransport ()

@property (strong, nonatomic, readwrite) SREventSourceStreamReader *eventSource;
@property (assign, nonatomic, readwrite) NSInteger reconnectDelay;
@property (assign, nonatomic, readwrite) NSInteger initializedCalled;

- (void)openConnection:(SRConnection *)connection data:(NSString *)data initializeCallback:(void (^)(void))initializeCallback errorCallback:(void (^)(SRErrorByReferenceBlock))errorCallback;

@end

@implementation SRServerSentEventsTransport

@synthesize connectionTimeout = _connectionTimeout;
@synthesize eventSource = _eventSource;
@synthesize reconnectDelay = _reconnectDelay;
@synthesize initializedCalled = _initializedCalled;

static NSString * const kTransportName = @"serverSentEvents";

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
    if([connection isDisconnecting])
    {
        return;
    }
    
    //Wait for a bit before reconnecting
    [NSTimer scheduledTimerWithTimeInterval:_reconnectDelay block:^
    {
        //Now attempt a reconnect
        [self openConnection:connection data:data initializeCallback:nil errorCallback:nil];
    } repeats:NO];
}

- (void)openConnection:(SRConnection *)connection data:(NSString *)data initializeCallback:(void (^)(void))initializeCallback errorCallback:(void (^)(SRErrorByReferenceBlock))errorCallback
{
    // If we're reconnecting add /connect to the url
    BOOL reconnecting = initializeCallback == nil;
    
    NSString *url = [(reconnecting ? connection.url : [connection.url stringByAppendingString:kConnectEndPoint]) stringByAppendingFormat:@"%@",[self getReceiveQueryString:connection data:data]];

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
                if (errorCallback != nil && 
                    _initializedCalled == 0)
                {
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_HTTP_BASED_TRANSPORT
                    SR_DEBUG_LOG(@"[SERVER_SENT_EVENTS] isFaulted will report to errorCallback");
#endif
                    _initializedCalled = 1;
                    
                    SRErrorByReferenceBlock errorBlock = ^(NSError ** error)
                    {
                        if(error)
                        {
                            *error = response.error;
                        }
                    };
                    errorCallback(errorBlock);
                }
                else if(reconnecting)
                {
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_HTTP_BASED_TRANSPORT
                    SR_DEBUG_LOG(@"[SERVER_SENT_EVENTS] isFaulted will report to connection");
#endif
                    // Only raise the error event if we failed to reconnect
                    [connection didReceiveError:response.error];
                }
            }
            
            if(reconnecting) //&& !CancellationToken.IsCancellationRequested) //TODO: Not cancelled
            {
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_HTTP_BASED_TRANSPORT
                SR_DEBUG_LOG(@"[SERVER_SENT_EVENTS] reconnecting");
#endif
                connection.state = reconnecting;
                
                //Retry
                [self reconnect:connection data:data];
            }
        }
        else
        {
            _eventSource = [[SREventSourceStreamReader alloc] initWithStream:response.stream];
            __weak SRServerSentEventsTransport *_transport = self;
            __block BOOL retry = YES;
            
            _eventSource.opened = ^()
            {
                if(initializeCallback != nil && _transport.initializedCalled == 0)
                {
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_HTTP_BASED_TRANSPORT
                    SR_DEBUG_LOG(@"[SERVER_SENT_EVENTS] connection is initialized");
#endif
                    _transport.initializedCalled = 1;
                    
                    initializeCallback();
                }
                
                if(reconnecting)
                {
                    //Change the status to connected
                    connection.state = connected;
                    
                    // Raise the reconnect event if the connection comes back up
                    [connection didReconnect];
                }
            };
            
            _eventSource.error = ^(NSError * error)
            {
                [connection didReceiveError:error];
            };
            
            _eventSource.message = ^(SRSseEvent * sseEvent)
            {
                if(sseEvent.type == Data)
                {
                    if([sseEvent.data caseInsensitiveCompare:@"initialized"] == NSOrderedSame)
                    {
                        return;
                    }
                }
                
                BOOL timedOut = NO;
                BOOL disconnect = NO;
                
                [_transport processResponse:connection response:sseEvent.data timedOut:&timedOut disconnected:&disconnect];
                
                if(disconnect)
                {
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_HTTP_BASED_TRANSPORT
                    SR_DEBUG_LOG(@"[SERVER_SENT_EVENTS] disconnectReceived should disconnect");
#endif
                    retry = NO;
                }
            };
            
            _eventSource.closed = ^()
            {
                if(retry)// && !CancellationToken.IsCancellationRequested)) //TODO: Not cancelled
                {
                    connection.state = reconnecting;
                    
                    [_transport reconnect:connection data:data];
                }
                else
                {
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_HTTP_BASED_TRANSPORT
                    SR_DEBUG_LOG(@"[SERVER_SENT_EVENTS] will abort connection");
#endif
                    [connection stop];
                }
            };
            
            [_eventSource start];
        }
    }];
    
    if (initializeCallback != nil)
    {
        [NSTimer scheduledTimerWithTimeInterval:_connectionTimeout block:
        ^{
            if(_initializedCalled == 0)
            {
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_HTTP_BASED_TRANSPORT
                SR_DEBUG_LOG(@"[SERVER_SENT_EVENTS] connection did timeout");
#endif
                _initializedCalled = 1;
                
                // Stop the connection
                [self stop:connection];
                
                // Connection timeout occured
                if (errorCallback != nil)
                {
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
                    errorCallback(errorBlock);
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_HTTP_BASED_TRANSPORT
                    SR_DEBUG_LOG(@"[SERVER_SENT_EVENTS] did call errorCallBack with timeout error");
#endif
                }
            }
        } repeats:NO];
    }
}

- (void)dealloc
{
    _eventSource = nil;
    _connectionTimeout = 0;
    _reconnectDelay = 0;
    _initializedCalled = 0;
}

@end