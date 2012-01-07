//
//  SRLongPollingTransport.m
//  SignalR
//
//  Created by Alex Billingsley on 10/17/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "SRLongPollingTransport.h"

#import "SBJson.h"

void (^prepareRequest)(NSMutableURLRequest *);

@interface SRLongPollingTransport()

- (void)_processResponse:(SRConnection *)connection response:(NSString *)response;

@end

@implementation SRLongPollingTransport

- (void)start:(SRConnection *)connection
{
    NSString *url = connection.url;
    
    if(connection.messageId == nil){
        url = [url stringByAppendingString:kConnectEndPoint];
    }

    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    if (connection.data) [parameters setObject:[connection.data urlEncodedString] forKey:kConnectionData];    
    if(connection.messageId) {
        [parameters setObject:[connection.messageId stringValue] forKey:kMessageId];
    }
    [parameters setObject:connection.connectionId forKey:kConnectionId];
    [parameters setObject:kLongPollingTransport forKey:kTransport];
    if([connection.groups count]>0)[parameters setObject:[connection.groups componentsJoinedByString:@","] forKey:kGroups];

    url = [NSString addQueryStringToUrlString:url withDictionary:parameters];
#if DEBUG
    NSLog(@"%@",url);
#endif
    prepareRequest = ^(NSMutableURLRequest * request){
#if TARGET_IPHONE || TARGET_IPHONE_SIMULATOR
        [request setValue:[connection createUserAgentString:@"SignalR.Client.iOS"] forHTTPHeaderField:@"User-Agent"];
#elif TARGET_OS_MAC
        [request setValue:[connection createUserAgentString:@"SignalR.Client.MAC"] forHTTPHeaderField:@"User-Agent"];
#endif
    };
    
    [[HttpHelper sharedHttpRequestManager] postAsync:connection url:url requestPreparer:prepareRequest onCompletion:
     ^(SRConnection *connection, id response) {
#if DEBUG
        NSLog(@"startDidReceiveResponse: %@",response);
#endif
        BOOL isFaulted = ([response isKindOfClass:[NSError class]] || 
                          [response isEqualToString:@""] || response == nil ||
                          [response isEqualToString:@"null"]);
        
        @try {
            if([response isKindOfClass:[NSString class]])
            {
                if(!isFaulted)
                {
                    [self _processResponse:connection response:response];
                }
            }
        }
        @finally {
            if(isFaulted)
            {
                if([response isKindOfClass:[NSError class]])[connection didReceiveError:response];
                
                if(connection.isActive){
                    [self performSelector:@selector(start:) withObject:connection afterDelay:2];
                }
            }
            else
            {
                if (connection.isActive) {
                    [self start:connection];
                }
            }
        }
    }];
}

- (void)send:(SRConnection *)connection withData:(NSString *)data onCompletion:(void(^)(SRConnection *, id))block
{       
    NSString *url = connection.url;
    url = [url stringByAppendingString:kSendEndPoint];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:connection.connectionId forKey:kConnectionId];
    [parameters setObject:kLongPollingTransport forKey:kTransport];
        
    url = [NSString addQueryStringToUrlString:url withDictionary:parameters];
#if DEBUG
    NSLog(@"%@",url);
#endif
    NSMutableDictionary *postData = [[NSMutableDictionary alloc] init];
    [postData setObject:[data urlEncodedString] forKey:kData];

    if(block == nil)
    {
        prepareRequest = ^(NSMutableURLRequest * request){
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

- (void)stop:(SRConnection *)connection
{
    
}

#pragma mark - Private

- (void)_processResponse:(SRConnection *)connection response:(NSString *)response
{
    if(connection.messageId == nil){
        connection.messageId = [NSNumber numberWithInt:0];
    }
    
    @try {
        id result = [[SBJsonParser new] objectWithString:response];
        if([result isKindOfClass:[NSDictionary class]])
        {
            id messageId = [result objectForKey:kResponse_MessageId];
            if(messageId && [messageId isKindOfClass:[NSNumber class]]){
                connection.messageId = messageId;
            }
            
            id messageData = [result objectForKey:kResponse_Messages];
            if(messageData && [messageData isKindOfClass:[NSArray class]])
            {
                for (id message in messageData) {   
                    if([message isKindOfClass:[NSDictionary class]]){
                        [connection didReceiveData:[[SBJsonWriter new] stringWithObject:message]];
                    }
                    else if([message isKindOfClass:[NSString class]]){
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
                    for (NSString *group in groups) {
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
