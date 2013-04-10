//
//  SRTransportHelper.m
//  SignalR
//
//  Created by Alex Billingsley on 4/8/13.
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

#import "SRTransportHelper.h"

#import "SRLog.h"
#import "NSObject+SRJSON.h"

@implementation SRTransportHelper

+ (void)getNegotiationResponse:(id <SRHttpClient>)httpClient connection:(id <SRConnectionInterface>)connection completionHandler:(void (^)(SRNegotiationResponse *response))block {
    
    if (httpClient == nil) {
        //throw new ArgumentNullException("httpClient");
    }
    
    if (connection == nil) {
        //throw new ArgumentNullException("connection");
    }
    
    NSString *negotiateUrl = [connection.url stringByAppendingString:@"negotiate"];
    negotiateUrl = [negotiateUrl stringByAppendingString:[self appendBaseUrl:negotiateUrl withConnectionQueryString:connection]];
    
    [httpClient get:negotiateUrl requestPreparer:^(id<SRRequest> request) {
        [request setTimeoutInterval:30];
        
        [connection prepareRequest:request];
    } completionHandler:^(id<SRResponse> response) {
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

//?transport=<transportname>&connectionToken=<connectionToken>&messageId=<messageId_or_Null>&groupsToken=<groupsToken>&connectionData=<data><customquerystring>
+ (NSString *)receiveQueryString:(id <SRConnectionInterface>)connection data:(NSString *)data transport:(NSString *)transport {
    
    if (connection == nil) {
        //throw new ArgumentNullException("connection");
    }
    
    NSMutableString *queryStringBuilder = [NSMutableString string];
    [queryStringBuilder appendFormat:@"?transport=%@",transport];
    [queryStringBuilder appendFormat:@"&connectionToken=%@",[connection.connectionToken stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    
    if(connection.messageId) {
        [queryStringBuilder appendFormat:@"&messageId=%@",[connection.messageId stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    }
    
    if (connection.groupsToken != nil) {
        [queryStringBuilder appendFormat:@"&groupsToken=%@",[connection.groupsToken stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    }
    
    if (data != nil) {
        [queryStringBuilder appendFormat:@"&connectionData=%@",[data stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    }
    
    NSString *customQuery = connection.queryString;
    
    if (customQuery != nil && ![customQuery isEqualToString:@""]) {
        [queryStringBuilder appendFormat:@"&%@",customQuery];
    }
    
    return queryStringBuilder;
}

+ (NSString *)appendBaseUrl:(NSString *)baseUrl withConnectionQueryString:(id <SRConnectionInterface>)connection
{
    if (connection == nil) {
        //throw new ArgumentNullException("connection");
    }
    
    if (baseUrl == nil) {
        baseUrl = @"";
    }
    
    NSString *queryString = @"";
    
    if (connection.queryString != nil && ![connection.queryString isEqualToString:@""]) {
        NSString *appender = @"";
        // If the custom query string already starts with an ampersand or question mark
        // then we dont have to use any appender, it can be empty.
        if (![connection.queryString hasPrefix:@"?"] && ![connection.queryString hasPrefix:@"&"])
        {
            appender = @"?";
            
            if ([baseUrl rangeOfString:appender options:NSCaseInsensitiveSearch].location != NSNotFound)
            {
                appender = @"&";
            }
        }
        
        queryString = [[queryString stringByAppendingString:appender] stringByAppendingString:connection.queryString];        
    }
    
    return queryString;
}

+ (void)processResponse:(id <SRConnectionInterface>)connection response:(NSString *)response timedOut:(BOOL *)timedOut disconnected:(BOOL *)disconnected {
    
    if (connection == nil) {
        //throw new ArgumentNullException("connection");
    }
    
    *timedOut = NO;
    *disconnected = NO;
    
    if(response == nil || [response isEqualToString:@""]) {
        return;
    }
    
    @try {
        id result = [response SRJSONValue];
        if([result isKindOfClass:[NSDictionary class]]) {
            
            if (result[@"I"] != nil) {
                [connection didReceiveData:response];
                return;
            }
            
            *timedOut = [result[@"T"] boolValue];
            *disconnected = [result[@"D"] boolValue];
            
            if(*disconnected) {
                return;
            }
            
            [self updateGroups:connection groupsToken:result[@"G"]];
            
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

+ (void)updateGroups:(id <SRConnectionInterface>)connection groupsToken:(NSString *)token {
    if (token != nil) {
        connection.groupsToken = token;
    }
}

@end
