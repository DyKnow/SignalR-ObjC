//
//  SRHttpBasedTransport.m
//  SignalR
//
//  Created by Alex Billingsley on 1/7/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import "SRHttpBasedTransport.h"

#import "SRConnection.h"
#import "SRConnectionExtensions.h"

#import "SBJson.h"
#import "SRHttpHelper.h"
#import "NSDictionary+QueryString.h"
#import "NSString+QueryString.h"
#import "ASIHTTPRequest.h"

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

- (void)onStart:(SRConnection *)connection data:(NSString *)data initializeCallback:(void(^)(void))initializeCallback errorCallback:(void(^)(id))errorCallback
{
    //override this method
    [NSException raise:@"AbstractClassException" format:@"Must use an overriding class of DKHttpBasedTransport"];
}

- (void)send:(SRConnection *)connection withData:(NSString *)data onCompletion:(void(^)(id))block
{       
    NSString *url = connection.url;
    url = [url stringByAppendingString:kSendEndPoint];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:connection.connectionId forKey:kConnectionId];
    [parameters setObject:_transport forKey:kTransport];
    
    url = [url stringByAppendingFormat:@"%@",[self getSendQueryString:connection]];

    NSMutableDictionary *postData = [[NSMutableDictionary alloc] init];
    [postData setObject:[data stringByEscapingForURLQuery] forKey:kData];
    
    if(block == nil)
    {
        [SRHttpHelper postAsync:url requestPreparer:^(ASIHTTPRequest * request)
        {
            [connection prepareRequest:request];
        } 
        postData:postData continueWith:
         ^(id response) 
        {
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
        [SRHttpHelper postAsync:url requestPreparer:^(ASIHTTPRequest * request)
        {
            [connection prepareRequest:request];
        }
        postData:postData continueWith:block];
    }
}

- (void)stop:(SRConnection *)connection
{
    ASIHTTPRequest *httpRequest = [connection getValue:kHttpRequestKey];
    
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
    return (error != nil && (error.code == ASIRequestCancelledErrorType));
}

//?transport=<transportname>&connectionId=<connectionId>&messageId=<messageId_or_Null>&groups=<groups>&connectionData=<data>
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
    
    if([connection.groups count]>0)
    {
        [parameters setObject:[connection.groups componentsJoinedByString:@","] forKey:kGroups];
    }
    else
    {
        [parameters setObject:[NSString stringWithFormat:@""] forKey:kGroups];
    }
    
    if (data) 
    {
        [parameters setObject:[data stringByEscapingForURLQuery] forKey:kConnectionData]; 
    }
    else
    {
        [parameters setObject:[NSString stringWithFormat:@""] forKey:kConnectionData];
    }
    return [NSString stringWithFormat:@"?%@",[parameters stringWithFormEncodedComponents]];
}

//?transport=<transportname>&connectionId=<connectionId>
- (NSString *)getSendQueryString:(SRConnection *)connection
{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:_transport forKey:kTransport];
    [parameters setObject:connection.connectionId forKey:kConnectionId];
    
    return [NSString stringWithFormat:@"?%@",[parameters stringWithFormEncodedComponents]];
}

- (void)prepareRequest:(ASIHTTPRequest *)request forConnection:(SRConnection *)connection;
{
    //Setup the user agent alogn with and other defaults
    [connection prepareRequest:request];
    
    [connection.items setObject:request forKey:kHttpRequestKey];
}

- (void)onBeforeAbort:(SRConnection *)connection
{
    //override this method
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
