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
#import "SRConnection.h"
#import "SRLog.h"
#import "SRNegotiationResponse.h"

#import "NSObject+SRJSON.h"

@interface SRHttpBasedTransport()

- (NSString *)getCustomQueryString:(SRConnection *)connection;

@end

@implementation SRHttpBasedTransport

- (id) initWithHttpClient:(id <SRHttpClient>)httpClient transport:(NSString *)transport {
    if (self = [super init]) {
        _httpClient = httpClient;
        _transport = transport;
    }
    return self;
}

- (void)negotiate:(SRConnection *)connection continueWith:(void (^)(SRNegotiationResponse *response))block {
    [SRHttpBasedTransport getNegotiationResponse:_httpClient connection:connection continueWith:block];
}

+ (void)getNegotiationResponse:(id <SRHttpClient>)httpClient connection:(SRConnection *)connection continueWith:(void (^)(SRNegotiationResponse *response))block {
    NSString *negotiateUrl = [connection.url stringByAppendingString:@"negotiate"];
    
    [httpClient getAsync:negotiateUrl requestPreparer:^(id<SRRequest> request) {
        [request setTimeoutInterval:30];
        
        [connection prepareRequest:request];
    } continueWith:^(id<SRResponse> response) {
        NSString *raw = response.string;
        
        if (raw == nil || [raw isEqualToString:@""]) {
            SRLogHTTPTransport(@"negotiation failed, connection will stop");

            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
            userInfo[NSLocalizedFailureReasonErrorKey] = NSInternalInconsistencyException;
            userInfo[NSLocalizedDescriptionKey] = [NSString stringWithFormat:NSLocalizedString(@"Server negotiation failed.",@"NSInternalInconsistencyException")];
            NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:NSLocalizedString(@"com.SignalR-ObjC.%@",@""),NSStringFromClass([self class])] 
                                                 code:0 
                                             userInfo:userInfo];
            [connection didReceiveError:error];
            [connection stop];
            return;
        }
        
        SRLogHTTPTransport(@"negotiation did receive response %@",raw);
        
        if(block) {
            block([[SRNegotiationResponse alloc] initWithDictionary:[raw SRJSONValue]]);
        }
    }];
}

#pragma mark -
#pragma mark SRConnectionTransport Protocol

- (void)start:(SRConnection *)connection withData:(NSString *)data continueWith:(void (^)(id response))tcs {
    [self onStart:connection data:data initializeCallback:^{
        if(tcs)
            tcs(nil);
    } errorCallback:^(SRErrorByReferenceBlock block) {
        NSError *error = nil;
        if (tcs && block){
            block(&error);
            tcs(error);
        }
    }];
}

- (void)onStart:(SRConnection *)connection data:(NSString *)data initializeCallback:(void (^)(void))initializeCallback errorCallback:(void (^)(SRErrorByReferenceBlock))errorCallback {
    [NSException raise:NSGenericException format:NSLocalizedString(@"Must use an overriding class of SRHttpBasedTransport",@"")];
}

- (void)send:(SRConnection *)connection withData:(NSString *)data continueWith:(void (^)(id response))block {
    
    if (connection == nil) {
        [NSException raise:NSInvalidArgumentException format:NSLocalizedString(@"Connection should be non-null",@"")];
    }
    
    NSString *url = [connection.url stringByAppendingString:@"send"];
    url = [url stringByAppendingFormat:@"%@",[self getSendQueryString:connection]];

    NSDictionary *postData = @{
        @"data" : data
    };
    
    SRLogHTTPTransport(@"will send data");
    
    [_httpClient postAsync:url requestPreparer:^(id<SRRequest> request) {
        [connection prepareRequest:request];
    } postData:postData continueWith:^(id<SRResponse> response) {
        NSString *raw = response.string;
        
        if (raw == nil || [raw isEqualToString:@""]) {
            return;
        }

        if(block) {
            block([raw SRJSONValue]);
        }
    }];
}

- (void)abort:(SRConnection *)connection {
    SRLogHTTPTransport(@"will stop transport");

    NSString *url = [connection.url stringByAppendingString:@"abort"];
    url = [url stringByAppendingFormat:@"%@",[self getSendQueryString:connection]];
    
    [_httpClient postAsync:url requestPreparer:^(id <SRRequest> request){ [connection prepareRequest:request]; } continueWith:nil];
}

#pragma mark - 
#pragma mark Protected Helpers

//?transport=<transportname>&connectionId=<connectionId>&messageId=<messageId_or_Null>&groups=<groups>&connectionData=<data><customquerystring>
- (NSString *)getReceiveQueryString:(SRConnection *)connection data:(NSString *)data {
    NSMutableString *queryStringBuilder = [NSMutableString string];
    [queryStringBuilder appendFormat:@"?transport=%@",_transport];
    [queryStringBuilder appendFormat:@"&connectionId=%@",[connection.connectionId stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];

    if(connection.messageId) {
        [queryStringBuilder appendFormat:@"&messageId=%@",[connection.messageId stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    }
    
    if (connection.groups && [connection.groups count] > 0) {
        [queryStringBuilder appendFormat:@"&groups=%@",[[connection.groups SRJSONRepresentation] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    }
    
    if (data != nil) {
        [queryStringBuilder appendFormat:@"&connectionData=%@",[data stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    }

    NSString *customQuery = [self getCustomQueryString:connection];
    
    if (customQuery != nil && ![customQuery isEqualToString:@""]) {
        [queryStringBuilder appendFormat:@"&%@",customQuery];
    }
    
    return queryStringBuilder;
}

//?transport=<transportname>&connectionId=<connectionId><customquerystring>
- (NSString *)getSendQueryString:(SRConnection *)connection {
    return [NSString stringWithFormat:@"?transport=%@&connectionId=%@%@",_transport,connection.connectionId,[self getCustomQueryString:connection]];
}

- (void)processResponse:(SRConnection *)connection response:(NSString *)response timedOut:(BOOL *)timedOut disconnected:(BOOL *)disconnected {
    *timedOut = NO;
    *disconnected = NO;
    
    if(response == nil || [response isEqualToString:@""]) {
        return;
    }
    
    @try {
        id result = [response SRJSONValue];
        if([result isKindOfClass:[NSDictionary class]]) {
            *timedOut = [result[@"T"] boolValue];
            *disconnected = [result[@"D"] boolValue];
            
            if(*disconnected) {
                return;
            }
            
            [self updateGroups:connection resetGroups:result[@"R"] addedGroups:result[@"G"] removedGroups:result[@"g"]];
            
            id messages = result[@"M"];
            if(messages && [messages isKindOfClass:[NSArray class]])
            {
                for (id message in messages) 
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
                
                NSString *messageId = result[@"C"];
                if(messageId)
                {
                    connection.messageId = messageId;
                }
            }
        }
    }
    @catch (NSError *ex) {
        SRLogHTTPTransport(@"error while processing messages %@",ex);

        [connection didReceiveError:ex];
    }
}

- (void)updateGroups:(SRConnection *)connection resetGroups:(NSArray *)resetGroups addedGroups:(NSArray *)addedGroups removedGroups:(NSArray *)removedGroups {
    if (resetGroups){
        [connection.groups removeAllObjects];
        for (id group in resetGroups) {
            [connection.groups addObject:group];
        }
    } else {
        for (id group in addedGroups) {
            [connection.groups addObject:group];
        }
        
        for (id group in removedGroups) {
#warning TODO Make Sure this works properly...
            [connection.groups removeObject:group];
        }
    }
}

- (NSString *)getCustomQueryString:(SRConnection *)connection {
    return (connection.queryString == nil || [connection.queryString isEqualToString:@""] == YES) ? @"" : [@"&" stringByAppendingString:connection.queryString] ;
}

- (void)dealloc
{
    _httpClient = nil;
    _transport = nil;
}
@end
