//
//  SRHttpBasedTransport.m
//  SignalR
//
//  Created by Alex Billingsley on 1/7/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import "SRHttpBasedTransport.h"
#import "SRSignalRConfig.h"

#import "SBJson.h"
#import "AFNetworking.h"
#import "SRHttpHelper.h"
#import "SRConnection.h"
#import "SRConnectionExtensions.h"

#import "NSDictionary+QueryString.h"
#import "NSString+QueryString.h"

@interface SRHttpBasedTransport()

- (NSString *)getCustomQueryString:(SRConnection *)connection;

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

- (void)start:(SRConnection *)connection withData:(NSString *)data continueWith:(void (^)(id))tcs
{
    [self onStart:connection data:data initializeCallback:^{ if(tcs) tcs(nil); } 
    errorCallback:^(SRErrorByReferenceBlock block) {
        NSError *error = nil;
        if (tcs && block)
        {
            block(&error);
            tcs(error);
        }
    }];
}

- (void)onStart:(SRConnection *)connection data:(NSString *)data initializeCallback:(void (^)(void))initializeCallback errorCallback:(void (^)(SRErrorByReferenceBlock))errorCallback
{
    [NSException raise:@"AbstractClassException" format:@"Must use an overriding class of DKHttpBasedTransport"];
}

- (void)send:(SRConnection *)connection withData:(NSString *)data continueWith:(void (^)(id response))block
{       
    NSString *url = connection.url;
    url = [url stringByAppendingString:kSendEndPoint];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:connection.connectionId forKey:kConnectionId];
    [parameters setObject:_transport forKey:kTransport];
    
    url = [url stringByAppendingFormat:@"%@",[self getSendQueryString:connection]];

    NSMutableDictionary *postData = [[NSMutableDictionary alloc] init];
    [postData setObject:[data stringByEscapingForURLQuery] forKey:kData];
    
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_LONG_POLLING || DEBUG_HTTP_BASED_TRANSPORT
    SR_DEBUG_LOG(@"[HTTP_BASED_TRANSPORT] will send data");
#endif
    
    if(block == nil)
    {
        [SRHttpHelper postAsync:url requestPreparer:^(id request)
        {
            [connection prepareRequest:request];
        } 
        postData:postData continueWith:
        ^(id response)
        {
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
        [SRHttpHelper postAsync:url requestPreparer:^(id request)
        {
            [connection prepareRequest:request];
        }
        postData:postData continueWith:block];
    }
}

- (void)stop:(SRConnection *)connection
{
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_LONG_POLLING || DEBUG_HTTP_BASED_TRANSPORT
    SR_DEBUG_LOG(@"[HTTP_BASED_TRANSPORT] will stop transport");
#endif
    AFHTTPRequestOperation *httpRequest = [connection getValue:kHttpRequestKey];
    
    if(httpRequest != nil)
    {
        @try 
        {
            [self onBeforeAbort:connection];
            [httpRequest cancel];
        }
        @catch (NSError *error) {
            //NotImplementedException
        }
    }
}

#pragma mark - 
#pragma mark Protected Helpers

- (BOOL)isRequestAborted:(NSError *)error
{
    return (error != nil && ([error.domain isEqualToString:AFNetworkingErrorDomain]));
}

//?transport=<transportname>&connectionId=<connectionId>&messageId=<messageId_or_Null>&groups=<groups>&connectionData=<data><customquerystring>
- (NSString *)getReceiveQueryString:(SRConnection *)connection data:(NSString *)data
{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:_transport forKey:kTransport];
    [parameters setObject:connection.connectionId forKey:kConnectionId];
    
    if(connection.messageId) 
    {
        [parameters setObject:[connection.messageId stringValue] forKey:kMessageId];
    }
    else
    {
        [parameters setObject:[NSString stringWithFormat:@""] forKey:kMessageId];
    }
    
    [parameters setObject:[[SBJsonWriter new] stringWithObject:connection.groups] forKey:kGroups];
    
    if (data) 
    {
        [parameters setObject:[data stringByEscapingForURLQuery] forKey:kConnectionData]; 
    }
    else
    {
        [parameters setObject:[NSString stringWithFormat:@""] forKey:kConnectionData];
    }
    return [NSString stringWithFormat:@"?%@%@",[parameters stringWithFormEncodedComponents],[self getCustomQueryString:connection]];
}

//?transport=<transportname>&connectionId=<connectionId><customquerystring>
- (NSString *)getSendQueryString:(SRConnection *)connection
{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:_transport forKey:kTransport];
    [parameters setObject:connection.connectionId forKey:kConnectionId];
    
    return [NSString stringWithFormat:@"?%@%@",[parameters stringWithFormEncodedComponents],[self getCustomQueryString:connection]];
}

- (void)prepareRequest:(id)request forConnection:(SRConnection *)connection;
{
    //Setup the user agent alogn with and other defaults
    [connection prepareRequest:request];
    
    if([request isKindOfClass:[AFHTTPRequestOperation class]])
    {
        [connection.items setObject:request forKey:kHttpRequestKey];
    }
}

- (void)onBeforeAbort:(SRConnection *)connection
{
    //override this method
}

- (void)processResponse:(SRConnection *)connection response:(NSString *)response timedOut:(BOOL *)timedOut disconnected:(BOOL *)disconnected
{
    *timedOut = NO;
    *disconnected = NO;
    
    if(response == nil || [response isEqualToString:@""])
    {
        return;
    }
    
    if(connection.messageId == nil)
    {
        connection.messageId = [NSNumber numberWithInt:0];
    }
    
    @try 
    {
        id result = [[SBJsonParser new] objectWithString:response];
        if([result isKindOfClass:[NSDictionary class]])
        {
            *timedOut = [[result objectForKey:kResponse_TimedOut] boolValue];
            *disconnected = [[result objectForKey:kResponse_Disconnected] boolValue];
            
            if(*disconnected)
            {
                return;
            }
            
            NSInteger messageId = [[result objectForKey:kResponse_MessageId] integerValue];
            if(messageId)
            {
                connection.messageId = [NSNumber numberWithInteger:messageId];
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
                    connection.groups = [NSMutableArray arrayWithArray:groups];
                }
            }
        }
    }
    @catch (NSError *ex) {
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_LONG_POLLING || DEBUG_HTTP_BASED_TRANSPORT
        SR_DEBUG_LOG(@"[HTTP_BASED_TRANSPORT] error while processing messages %@",ex);
#endif
        [connection didReceiveError:ex];
    }
}

- (NSString *)getCustomQueryString:(SRConnection *)connection
{
    return (connection.queryString == nil || [connection.queryString isEqualToString:@""] == YES) ? @"" : [@"&" stringByAppendingString:connection.queryString] ;
}

- (void)dealloc
{
    _transport = nil;
}
@end
