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

#import "AFHTTPRequestOperation.h"
#import "SRConnectionInterface.h"
#import "SRHttpBasedTransport.h"
#import "SRLog.h"
#import "SRNegotiationResponse.h"

#import "NSObject+SRJSON.h"

@interface SRHttpBasedTransport()

@property (assign, nonatomic, readwrite) BOOL startedAbort;

@end

static inline NSString * SREscapeData(NSString *string) {
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)(NSString *)string, NULL,
                                                                                 (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                 kCFStringEncodingUTF8));
}

@implementation SRHttpBasedTransport

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

#pragma mark
#pragma mark SRClientTransportInterface

- (NSString *)name {
    return @"";
}

- (BOOL)supportsKeepAlive {
    return NO;
}

- (void)negotiate:(id<SRConnectionInterface>)connection
   connectionData:(NSString *)connectionData
completionHandler:(void (^)(SRNegotiationResponse * response, NSError *error))block {

    NSString *negotiateUrl = [connection.url stringByAppendingString:@"negotiate"];
    negotiateUrl = [negotiateUrl stringByAppendingString:[self appendBaseUrl:negotiateUrl withConnectionQueryString:connection]];
    
    NSString *appender = @"?";
    if ([negotiateUrl rangeOfString:appender].location != NSNotFound) {
        appender = @"&";
    }
    negotiateUrl = [negotiateUrl stringByAppendingString:appender];
    negotiateUrl = [negotiateUrl stringByAppendingString:@"clientProtocol="];
    negotiateUrl = [negotiateUrl stringByAppendingFormat:@"%@",connection.protocol];
    
    if (connectionData != nil && ![connectionData isEqualToString:@""]) {
        negotiateUrl = [negotiateUrl stringByAppendingString:@"&connectionData="];
        negotiateUrl = [negotiateUrl stringByAppendingString:SREscapeData(connectionData)];
    }
        
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:negotiateUrl]];
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest setTimeoutInterval:30];
    
    [connection prepareRequest:urlRequest];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
    [operation setResponseSerializer:[AFJSONResponseSerializer serializer]];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if(block) {
            block([[SRNegotiationResponse alloc] initWithDictionary:responseObject], nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(block) {
            block(nil, error);
        }
    }];
    [operation start];
}

- (void)start:(id<SRConnectionInterface>)connection
connectionData:(NSString *)connectionData
completionHandler:(void (^)(id response, NSError *error))block {
}

- (void)send:(id<SRConnectionInterface>)connection
        data:(NSString *)data
connectionData:(NSString *)connectionData
completionHandler:(void (^)(id response, NSError *error))block {

    SRLogHTTPTransport(@"will send data");
    
    NSString *url = [connection.url stringByAppendingString:@"send"];
    url = [url stringByAppendingString:[self sendQueryString:connection connectionData:connectionData]];
    
    id postData = @{
        @"data" : data
    };
    
    NSMutableArray *components = [NSMutableArray array];
    for (NSString *key in [postData allKeys]) {
        [components addObject:[NSString stringWithFormat:@"%@=%@",key,SREscapeData(postData[key])]];
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
    [operation setResponseSerializer:[AFJSONResponseSerializer serializer]];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [connection didReceiveData:responseObject];
        if(block) {
            block(responseObject, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [connection didReceiveError:error];
        if (block) {
            block(nil, error);
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

- (void)abort:(id<SRConnectionInterface>)connection
      timeout:(NSNumber *)timeout
connectionData:(NSString *)connectionData {

    // Ensure that an abort request is only made once
    if (!_startedAbort)
    {
        SRLogHTTPTransport(@"will stop transport");
        _startedAbort = YES;
        
        NSString *url = [connection.url stringByAppendingString:@"abort"];
        url = [url stringByAppendingString:[self sendQueryString:connection connectionData:connectionData]];
        
        NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
        [urlRequest setHTTPMethod:@"POST"];
        [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        //[urlRequest setTimeoutInterval:2];
        
        [connection prepareRequest:urlRequest];
        
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
        [operation setResponseSerializer:[AFJSONResponseSerializer serializer]];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            SRLogHTTPTransport(@"Clean disconnect failed. %@",error);
            [self completeAbort];
        }];
        [operation start];
    }
}

- (NSString *)sendQueryString:(id <SRConnectionInterface>)connection
               connectionData:(NSString *)connectionData {

    NSMutableString *queryStringBuilder = [NSMutableString string];
    [queryStringBuilder appendFormat:@"?transport=%@",[self name]];
    [queryStringBuilder appendFormat:@"&connectionData=%@",SREscapeData(connectionData)];
    [queryStringBuilder appendFormat:@"&connectionToken=%@",SREscapeData(connection.connectionToken)];
    
    NSString *customQuery = connection.queryString;
    
    if (customQuery != nil && ![customQuery isEqualToString:@""]) {
        [queryStringBuilder appendFormat:@"&%@",customQuery];
    }
    return queryStringBuilder;
}

- (NSString *)receiveQueryString:(id <SRConnectionInterface>)connection
                            data:(NSString *)data {
    
    NSMutableString *queryStringBuilder = [NSMutableString string];
    [queryStringBuilder appendFormat:@"?transport=%@",[self name]];
    [queryStringBuilder appendFormat:@"&connectionToken=%@",SREscapeData(connection.connectionToken)];
    
    if(connection.messageId) {
        [queryStringBuilder appendFormat:@"&messageId=%@",SREscapeData(connection.messageId)];
    }
    
    if (connection.groupsToken != nil) {
        [queryStringBuilder appendFormat:@"&groupsToken=%@",SREscapeData(connection.groupsToken)];
    }
    
    if (data != nil) {
        [queryStringBuilder appendFormat:@"&connectionData=%@",SREscapeData(data)];
    }
    
    NSString *customQuery = connection.queryString;
    
    if (customQuery != nil && ![customQuery isEqualToString:@""]) {
        [queryStringBuilder appendFormat:@"&%@",customQuery];
    }

    return queryStringBuilder;
}

- (NSString *)appendBaseUrl:(NSString *)baseUrl
  withConnectionQueryString:(id <SRConnectionInterface>)connection {
    
    if (baseUrl == nil) {
        baseUrl = @"";
    }
    
    NSString *queryString = @"";
    
    if (connection.queryString != nil && ![connection.queryString isEqualToString:@""]) {
        NSString *appender = @"";
        // If the custom query string already starts with an ampersand or question mark
        // then we dont have to use any appender, it can be empty.
        if (![connection.queryString hasPrefix:@"?"] && ![connection.queryString hasPrefix:@"&"]) {
            appender = @"?";
            
            if ([baseUrl rangeOfString:appender options:NSCaseInsensitiveSearch].location != NSNotFound) {
                appender = @"&";
            }
        }
        
        queryString = [[queryString stringByAppendingString:appender] stringByAppendingString:connection.queryString];
    }
    
    return queryString;
}

- (void)processResponse:(id <SRConnectionInterface>)connection
               response:(NSString *)response
        shouldReconnect:(BOOL *)shouldReconnect
           disconnected:(BOOL *)disconnected {

    [connection updateLastKeepAlive];
    
    *shouldReconnect = NO;
    *disconnected = NO;
    
    if(response == nil || [response isEqualToString:@""]) {
        return;
    }
    
    id result = [response SRJSONValue];
    if([result isKindOfClass:[NSDictionary class]]) {
        if (result[@"I"] != nil) {
            [connection didReceiveData:result];
            return;
        }
        
        *shouldReconnect = [result[@"T"] boolValue];
        *disconnected = [result[@"D"] boolValue];
        
        if(*disconnected) {
            return;
        }
        
        connection.groupsToken = result[@"G"];
        
        id messages = result[@"M"];
        if(messages && [messages isKindOfClass:[NSArray class]])
        {
            connection.messageId = result[@"C"];
            
            for (id message in messages)
            {
                [connection didReceiveData:message];
            }
            
            if ([result[@"S"] boolValue])
            {
                //TODO: Call Initialized Callback
                //onInitialized();
            }
        }
    }
}

@end
