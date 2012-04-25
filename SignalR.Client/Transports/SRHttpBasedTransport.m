//
//  SRHttpBasedTransport.m
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

#import "SRHttpBasedTransport.h"
#import "SRSignalRConfig.h"

#import "NSObject+SRJSON.h"
#import "AFNetworking.h"
#import "SRConnection.h"
#import "SRConnectionExtensions.h"
#import "SRNegotiationResponse.h"

#import "NSDictionary+QueryString.h"
#import "NSString+QueryString.h"

@interface SRHttpBasedTransport()

- (NSString *)getCustomQueryString:(SRConnection *)connection;

@end

@implementation SRHttpBasedTransport

@synthesize httpClient = _httpClient;
@synthesize transport = _transport;

- (id) initWithHttpClient:(id <SRHttpClient>)httpClient transport:(NSString *)transport
{
    if (self = [super init])
    {
        _httpClient = httpClient;
        _transport = transport;
    }
    return self;
}

- (void)negotiate:(SRConnection *)connection continueWith:(void (^)(id))block
{
    [SRHttpBasedTransport getNegotiationResponse:_httpClient connection:connection continueWith:block];
}

+ (void)getNegotiationResponse:(id <SRHttpClient>)httpClient connection:(SRConnection *)connection continueWith:(void (^)(id))block
{
    NSString *negotiateUrl = [connection.url stringByAppendingString:kNegotiateRequest];
    
    [httpClient postAsync:negotiateUrl requestPreparer:^(id request)
    {
        if([request isKindOfClass:[NSMutableURLRequest class]])
        {
            [request setTimeoutInterval:30];
        }
        [connection prepareRequest:request];
    }
    continueWith:^(id response)
    {
#if DEBUG_HTTP_BASED_TRANSPORT
        SR_DEBUG_LOG(@"[HTTP_BASED_TRANSPORT] negotiation did receive response %@",response);
#endif
        BOOL isFaulted = ([response isKindOfClass:[NSError class]] || 
                          [response isEqualToString:@""] || response == nil ||
                          [response isEqualToString:@"null"]);
        
        if([response isKindOfClass:[NSString class]])
        {
            if(!isFaulted)
            {
                SRNegotiationResponse *negotiationResponse = [[SRNegotiationResponse alloc] initWithDictionary:[response SRJSONValue]];
                
                if(block)
                {
                    block(negotiationResponse);
                }
            }
        }
        
        if(isFaulted)
        {
#if DEBUG_CONNECTION
            SR_DEBUG_LOG(@"[CONNECTION] negotiation failed, connection will stop");
#endif
            [connection stop];
        }
    }];
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
    NSString *url = [connection.url stringByAppendingString:kSendEndPoint];
    url = [url stringByAppendingFormat:@"%@",[self getSendQueryString:connection]];

    NSMutableDictionary *postData = [[NSMutableDictionary alloc] init];
    [postData setObject:[data stringByEscapingForURLQuery] forKey:kData];
    
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_LONG_POLLING || DEBUG_HTTP_BASED_TRANSPORT
    SR_DEBUG_LOG(@"[HTTP_BASED_TRANSPORT] will send data");
#endif
    
    if(block == nil)
    {
        [_httpClient postAsync:url requestPreparer:^(id request)
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
        [_httpClient postAsync:url requestPreparer:^(id request)
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
    
    [parameters setObject:[connection.groups SRJSONRepresentation] forKey:kGroups];
    
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
    //Setup the user agent along with and other defaults
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
        id result = [response SRJSONValue];
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
                        [connection didReceiveData:[message SRJSONRepresentation]];
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
