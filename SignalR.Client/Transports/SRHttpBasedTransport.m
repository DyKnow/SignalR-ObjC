//
//  SRHttpBasedTransport.m
//  SignalR
//
//  Created by Alex Billingsley on 1/7/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import "SRHttpBasedTransport.h"

#import "SRConnection.h"

#import "SBJson.h"
#import "HttpHelper.h"
#import "NSString+Url.h"

void (^prepareRequest)(NSMutableURLRequest *);

@interface SRHttpBasedTransport()

@end

@implementation SRHttpBasedTransport

@synthesize transport = _transport;

- (id) initWithTransport:(NSString *)transport
{
    if (self = [super init])
    {
        _transport = transport;
    }
    return self;
}

#pragma mark -
#pragma mark SRConnectionTransport Protocol

- (void)start:(SRConnection *)connection withData:(NSString *)data
{
    [self onStart:connection data:data initializeCallback:nil errorCallback:nil];
}

- (void)send:(SRConnection *)connection withData:(NSString *)data onCompletion:(void(^)(SRConnection *, id))block
{       
    NSString *url = connection.url;
    url = [url stringByAppendingString:kSendEndPoint];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:connection.connectionId forKey:kConnectionId];
    [parameters setObject:_transport forKey:kTransport];
    
    url = [url stringByAppendingFormat:@"%@",[self getSendQueryString:connection]];

    NSMutableDictionary *postData = [[NSMutableDictionary alloc] init];
    [postData setObject:[data urlEncodedString] forKey:kData];
    
    if(block == nil)
    {
        prepareRequest = ^(NSMutableURLRequest * request){
            [connection.items setObject:request forKey:kHttpRequestKey];
#if TARGET_IPHONE || TARGET_IPHONE_SIMULATOR
            [request setValue:[connection createUserAgentString:@"SignalR.Client.iOS"] forHTTPHeaderField:@"User-Agent"];
#elif TARGET_OS_MAC
            [request setValue:[connection createUserAgentString:@"SignalR.Client.MAC"] forHTTPHeaderField:@"User-Agent"];
#endif
        };
        
        [[HttpHelper sharedHttpRequestManager] postAsync:connection url:url requestPreparer:prepareRequest postData:postData onCompletion:
         ^(SRConnection *connection, id response) {
#if DEBUG
             NSLog(@"sendDidReceiveResponse: %@",response);
#endif
             if([response isKindOfClass:[NSString class]])
             {
                 if([response isEqualToString:@""] == NO && response != nil)
                 {
                     [connection didReceiveData:response];
                 }
             }
         }];
    }
    else
    {
        [[HttpHelper sharedHttpRequestManager] postAsync:connection url:url requestPreparer:nil postData:parameters onCompletion:block];
    }
}

//TODO: Abort Request if one exists
- (void)stop:(SRConnection *)connection
{
    id httpRequest = [connection.items objectForKey:kHttpRequestKey];
    
    if(httpRequest != nil)
    {
        @try 
        {
            //onBeforeAbort
            //httpRequest.Abort();
        }
        @catch (NSError *error) {
            //NotImplementedException
        }
    }
}

#pragma mark - 
#pragma mark Protected Helpers

//TODO: figure out if the request is aborted
- (BOOL)isRequestAborted:(NSError *)error
{
    return NO;
}

//?transport=<transportname>&connectionId=<connectionId>&messageId=<messageId_or_Null>&&groups=<groups>&&connectionData=<data>
- (NSString *)getReceiveQueryString:(SRConnection *)connection data:(NSString *)data
{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:_transport forKey:kTransport];
    [parameters setObject:connection.connectionId forKey:kConnectionId];
    if(connection.messageId) 
    {
        [parameters setObject:[connection.messageId stringValue] forKey:kMessageId];
    }
    if([connection.groups count]>0)
    {
        [parameters setObject:[connection.groups componentsJoinedByString:@","] forKey:kGroups];
    }
    if (data) 
    {
        [parameters setObject:[data urlEncodedString] forKey:kConnectionData]; 
    }   
    return [NSString addQueryStringToUrlString:@"" withDictionary:parameters];
}

//?transport=<transportname>&connectionId=<connectionId>
- (NSString *)getSendQueryString:(SRConnection *)connection
{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:_transport forKey:kTransport];
    [parameters setObject:connection.connectionId forKey:kConnectionId];
    
    return [NSString addQueryStringToUrlString:@"" withDictionary:parameters];
}

- (void)onBeforeAbort:(SRConnection *)connection
{
    
}

- (void)onMessage:(SRConnection *)connection response:(NSString *)response
{
    if(connection.messageId == nil)
    {
        connection.messageId = [NSNumber numberWithInt:0];
    }
    
    @try 
    {
        id result = [[SBJsonParser new] objectWithString:response];
        if([result isKindOfClass:[NSDictionary class]])
        {
            id messageId = [result objectForKey:kResponse_MessageId];
            if(messageId && [messageId isKindOfClass:[NSNumber class]])
            {
                connection.messageId = messageId;
            }
            
            id messageData = [result objectForKey:kResponse_Messages];
            if(messageData && [messageData isKindOfClass:[NSArray class]])
            {
                for (id message in messageData) 
                {   
                    if([message isKindOfClass:[NSDictionary class]])
                    {
                        [connection didReceiveData:[[SBJsonWriter new] stringWithObject:message]];
                    }
                    else if([message isKindOfClass:[NSString class]])
                    {
                        [connection didReceiveData:message];
                    }
                }
            }
            
            id transportData = [result objectForKey:kResponse_TransportData];
            if(transportData && [transportData isKindOfClass:[NSDictionary class]])  
            {
                id groups = [transportData objectForKey:kResponse_Groups];
                if(groups && [groups isKindOfClass:[NSArray class]])
                {
                    for (NSString *group in groups) 
                    {
                        [connection.groups addObject:group];
                    }
                }
            }
        }
    }
    @catch (NSError *ex) {
#if DEBUG
        NSLog(@"Failed to respond: %@",ex);
#endif
        [connection didReceiveError:ex];
    }
}

@end
