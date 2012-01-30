//
//  SRLongPollingTransport.m
//  SignalR
//
//  Created by Alex Billingsley on 10/17/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "SRLongPollingTransport.h"
#import "SRSignalRConfig.h"

#import "SRHttpHelper.h"
#import "SRConnection.h"

typedef void (^onInitialized)(void);

@interface SRLongPollingTransport()

- (void)pollingLoop:(SRConnection *)connection data:(NSString *)data initializeCallback:(void (^)(void))initializeCallback errorCallback:(void (^)(SRErrorByReferenceBlock))errorCallback;

#define kTransportName @"longPolling"

@end

@implementation SRLongPollingTransport

- (id)init
{
    if(self = [super initWithTransport:kTransportName])
    {
        
    }
    return self;
}

- (void)onStart:(SRConnection *)connection data:(NSString *)data initializeCallback:(void (^)(void))initializeCallback errorCallback:(void (^)(SRErrorByReferenceBlock))errorCallback;
{
    [self pollingLoop:connection data:data initializeCallback:initializeCallback errorCallback:errorCallback];
}

- (void)pollingLoop:(SRConnection *)connection data:(NSString *)data initializeCallback:(void (^)(void))initializeCallback errorCallback:(void (^)(SRErrorByReferenceBlock))errorCallback
{    
    NSString *url = connection.url;
    
    if(connection.messageId == nil)
    {
        url = [url stringByAppendingString:kConnectEndPoint];
    }
    
    url = [url stringByAppendingFormat:@"%@",[self getReceiveQueryString:connection data:data]];
    
    [SRHttpHelper postAsync:url requestPreparer:^(id request)
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

        BOOL isFaulted = ([response isKindOfClass:[NSError class]] || 
                          [response isEqualToString:@""] || response == nil ||
                          [response isEqualToString:@"null"]);
        @try 
        {
            if([response isKindOfClass:[NSString class]])
            {
                if(!isFaulted)
                {
                    [self onMessage:connection response:response];
                }
            }
        }
        @finally 
        {
            BOOL requestAborted = NO;
            BOOL continuePolling = YES;
            
            if (isFaulted)
            {
#if DEBUG_LONG_POLLING || DEBUG_HTTP_BASED_TRANSPORT
                SR_DEBUG_LOG(@"[LONG_POLLING] isFaulted");
#endif
                if([response isKindOfClass:[NSError class]])
                {
                    if (errorCallback)
                    {
#if DEBUG_LONG_POLLING || DEBUG_HTTP_BASED_TRANSPORT
                        SR_DEBUG_LOG(@"[LONG_POLLING] will report error to errorCallback");
#endif
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
                            if(connection.isActive)
                            {
#if DEBUG_LONG_POLLING || DEBUG_HTTP_BASED_TRANSPORT
                                SR_DEBUG_LOG(@"[LONG_POLLING] will poll again in 2 seconds");
#endif
                                NSMethodSignature *signature = [self methodSignatureForSelector:@selector(pollingLoop:data:initializeCallback:errorCallback:)];
                                NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
                                [invocation setSelector:@selector(pollingLoop:data:initializeCallback:errorCallback:)];
                                [invocation setTarget:self ];
                                
                                NSArray *args = [[NSArray alloc] initWithObjects:connection,data,nil,nil, nil];
                                for(int i =0; i<[args count]; i++)
                                {
                                    int arguementIndex = 2 + i;
                                    NSString *argument = [args objectAtIndex:i];
                                    [invocation setArgument:&argument atIndex:arguementIndex];
                                }
                                [NSTimer scheduledTimerWithTimeInterval:2 invocation:invocation repeats:NO];
                            }
                        }
                    }
                }
            }
            else
            {
                if (continuePolling && !requestAborted && connection.isActive)
                {
#if DEBUG_LONG_POLLING || DEBUG_HTTP_BASED_TRANSPORT
                    SR_DEBUG_LOG(@"[LONG_POLLING] will poll again immediately");
#endif
                    [self pollingLoop:connection data:data initializeCallback:nil errorCallback:nil];
                }
            }
        }
    }];
    
    if (initializeCallback != nil)
    {
#if DEBUG_LONG_POLLING || DEBUG_HTTP_BASED_TRANSPORT
        SR_DEBUG_LOG(@"[LONG_POLLING] connection is initialized");
#endif
        // Only set this the first time
        initializeCallback();
    }
}

- (void)dealloc
{
    
}

@end
