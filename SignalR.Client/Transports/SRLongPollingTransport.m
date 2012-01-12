//
//  SRLongPollingTransport.m
//  SignalR
//
//  Created by Alex Billingsley on 10/17/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "SRLongPollingTransport.h"

#import "SRHttpHelper.h"
#import "SRConnection.h"

@interface SRLongPollingTransport()

- (void)pollingLoop:(SRConnection *)connection data:(NSString *)data;

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

- (void)onStart:(SRConnection *)connection data:(NSString *)data
{
    [self pollingLoop:connection data:data];
}

//TODO: Check if exception is an IOException
- (void)pollingLoop:(SRConnection *)connection data:(NSString *)data
{
    NSString *url = connection.url;
    
    if(connection.messageId == nil)
    {
        url = [url stringByAppendingString:kConnectEndPoint];
    }
    
    url = [url stringByAppendingFormat:@"%@",[self getReceiveQueryString:connection data:data]];
    
    [SRHttpHelper postAsync:url requestPreparer:^(ASIHTTPRequest * request)
    {
        [self prepareRequest:request forConnection:connection];
    } 
    continueWith:^(id response) 
    {
#if DEBUG
        NSLog(@"pollingLoopDidReceiveResponse: %@",response);
#endif
        // Clear the pending request
        [connection.items removeObjectForKey:kHttpRequestKey];

        //TODO:isFaulted is not correct there must be a better way to do this
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
                if([response isKindOfClass:[NSError class]])
                {
                    //Figure out if the request is aborted
                    requestAborted = [self isRequestAborted:response];
                    
                    //Sometimes a connection might have been closed by the server before we get to write anything
                    //So just try again and don't raise an error
                    //TODO: check for IOException
                    if(!requestAborted) //&& !(exception is IOExeption))
                    {
                        //Raise Error
                        [connection didReceiveError:response];
                        
                        //If the connection is still active after raising the error wait 2 seconds 
                        //before polling again so we arent hammering the server
                        if(connection.isActive)
                        {
                            NSMethodSignature *signature = [self methodSignatureForSelector:@selector(pollingLoop:data:)];
                            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
                            [invocation setSelector:@selector(pollingLoop:data:)];
                            [invocation setTarget:self ];
                            
                            NSArray *args = [[NSArray alloc] initWithObjects:connection,data,nil];
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
            else
            {
                if (continuePolling && !requestAborted && connection.isActive)
                {
                    [self pollingLoop:connection data:data];
                }
            }
        }
    }];
}

@end
