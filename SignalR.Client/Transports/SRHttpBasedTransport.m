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

#import "AFJSONRequestOperation.h"
#import "SRConnectionInterface.h"
#import "SRHttpBasedTransport.h"
#import "SRLog.h"
#import "SRNegotiationResponse.h"

#import "NSObject+SRJSON.h"

@interface SRHttpBasedTransport()

@property (assign, nonatomic, readwrite) BOOL startedAbort;

@end

@implementation SRHttpBasedTransport

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

#pragma mark
#pragma mark SRClientTransportInterface

- (NSString *)name {
    //TODO: Throw
    return @"";
}

- (BOOL)supportsKeepAlive {
    //TODO: Throw 
    return NO;
}

- (void)negotiate:(id <SRConnectionInterface>)connection completionHandler:(void (^)(SRNegotiationResponse *response))block {
    if (connection == nil) {
        //TODO: throw here
    }
    NSString *negotiateUrl = [connection.url stringByAppendingString:@"negotiate"];
    negotiateUrl = [negotiateUrl stringByAppendingString:[self appendBaseUrl:negotiateUrl withConnectionQueryString:connection]];
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:negotiateUrl]];
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest setTimeoutInterval:30];
    
    [connection prepareRequest:urlRequest];
    
    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:urlRequest];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if(block) {
            block([[SRNegotiationResponse alloc] initWithDictionary:responseObject]);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
    [operation start];
}

- (void)start:(id <SRConnectionInterface>)connection data:(NSString *)data completionHandler:(void (^)(id response))block {
    //TODO: Throw here
}

- (void)send:(id <SRConnectionInterface>)connection data:(NSString *)data completionHandler:(void (^)(id response))block {
    if (connection == nil) {
        //TODO: throw here
    }
    SRLogHTTPTransport(@"will send data");
    
    NSString *url = [connection.url stringByAppendingString:@"send"];
    url = [url stringByAppendingString:[self sendQueryString:connection]];
    
    id postData = @{
        @"data" : data
    };
    
    NSMutableArray *components = [NSMutableArray array];
    for (NSString *key in [postData allKeys]) {
        [components addObject:[NSString stringWithFormat:@"%@=%@",key,postData[key]]];
    }
    NSData *requestData = [[components componentsJoinedByString:@"&"] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setValue:[NSString stringWithFormat:@"%ld", (unsigned long)[requestData length]] forHTTPHeaderField:@"Content-Length"];
    [urlRequest setHTTPBody: requestData];
    
    [connection prepareRequest:urlRequest];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (operation.responseString == nil) {
            return;
        }
        
#warning TODO: this should be a json object instead...
        [connection didReceiveData:operation.responseString];
        
        if(block) {
            block([operation.responseString SRJSONValue]);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [connection didReceiveError:error];
        
        if (block) {
            block(error);
        }
    }];
    [operation start];
}

- (void)completeAbort {
    // Make any future calls to Abort() no-op
    // Abort might still run, but any ongoing aborts will immediately complete
    _startedAbort = YES;
}

- (BOOL)tryCompleteAbort {
    if (_startedAbort) {
        return YES;
    } else {
        return NO;
    }
}

- (void)lostConnection:(id<SRConnectionInterface>)connection {
    //TODO: Throw, Subclass should implement this.
}

#warning TODO: HANDLE TIMEOUT
- (void)abort:(id <SRConnectionInterface>)connection timeout:(NSNumber *)timeout {
    if (connection == nil) {
        //TODO: throw here
    }
    
    // Ensure that an abort request is only made once
    if (!_startedAbort)
    {
        SRLogHTTPTransport(@"will stop transport");
        _startedAbort = YES;
        
        NSString *url = [connection.url stringByAppendingString:@"abort"];
        url = [url stringByAppendingString:[self sendQueryString:connection]];
        
        NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
        [urlRequest setHTTPMethod:@"POST"];
        [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        //[urlRequest setTimeoutInterval:2];
        
        [connection prepareRequest:urlRequest];
        
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            SRLogHTTPTransport(@"Clean disconnect failed. %@",error);
            [self completeAbort];
        }];
        [operation start];
    }
}

- (NSString *)sendQueryString:(id <SRConnectionInterface>)connection {
    if (connection == nil) {
        //TODO: throw here
    }
    
    NSMutableString *queryStringBuilder = [NSMutableString string];
    [queryStringBuilder appendFormat:@"?transport=%@",[self name]];
    [queryStringBuilder appendFormat:@"&connectionToken=%@",[connection.connectionToken stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    
    NSString *customQuery = connection.queryString;
    
    if (customQuery != nil && ![customQuery isEqualToString:@""]) {
        [queryStringBuilder appendFormat:@"&%@",customQuery];
    }
    return queryStringBuilder;
}

- (NSString *)receiveQueryString:(id <SRConnectionInterface>)connection data:(NSString *)data {
    if (connection == nil) {
        //TODO: throw here
    }
    
    NSMutableString *queryStringBuilder = [NSMutableString string];
    [queryStringBuilder appendFormat:@"?transport=%@",[self name]];
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

- (NSString *)appendBaseUrl:(NSString *)baseUrl withConnectionQueryString:(id <SRConnectionInterface>)connection {
    if (connection == nil) {
        //TODO: throw here
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

- (void)processResponse:(id <SRConnectionInterface>)connection response:(NSString *)response timedOut:(BOOL *)timedOut disconnected:(BOOL *)disconnected {
    if (connection == nil) {
        //TODO: throw here
    }
    
    [connection updateLastKeepAlive];
    
    *timedOut = NO;
    *disconnected = NO;
    
    if(response == nil || [response isEqualToString:@""]) {
        return;
    }
    
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

- (void)updateGroups:(id <SRConnectionInterface>)connection groupsToken:(NSString *)token {
    if (token != nil) {
        connection.groupsToken = token;
    }
}

@end
