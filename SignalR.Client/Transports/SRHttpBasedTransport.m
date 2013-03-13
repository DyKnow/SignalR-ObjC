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
#import "SRConnectionInterface.h"
#import "SRLog.h"
#import "SRNegotiationResponse.h"

#import "NSObject+SRJSON.h"

@interface SRHttpBasedTransport()

+ (NSString *)getCustomQueryString:(id <SRConnectionInterface>)connection;

@end

@implementation SRHttpBasedTransport

- (instancetype)initWithHttpClient:(id <SRHttpClient>)httpClient transport:(NSString *)transport {
    if (self = [super init]) {
        _httpClient = httpClient;
        _transport = transport;
    }
    return self;
}

- (NSString *)name {
    return _transport;
}

- (void)negotiate:(id <SRConnectionInterface>)connection completionHandler:(void (^)(SRNegotiationResponse *response))block {
    [SRHttpBasedTransport getNegotiationResponse:_httpClient connection:connection completionHandler:block];
}

+ (void)getNegotiationResponse:(id <SRHttpClient>)httpClient connection:(id <SRConnectionInterface>)connection completionHandler:(void (^)(SRNegotiationResponse *response))block {
    NSString *negotiateUrl = [connection.url stringByAppendingString:@"negotiate"];
    negotiateUrl = [negotiateUrl stringByAppendingString:[self getCustomQueryString:connection]];
    
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

#pragma mark -
#pragma mark SRConnectionTransport Protocol

- (void)start:(id <SRConnectionInterface>)connection withData:(NSString *)data completionHandler:(void (^)(id response))tcs {
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

- (void)onStart:(id <SRConnectionInterface>)connection data:(NSString *)data initializeCallback:(void (^)(void))initializeCallback errorCallback:(void (^)(SRErrorByReferenceBlock))errorCallback {
    [NSException raise:NSGenericException format:NSLocalizedString(@"Must use an overriding class of SRHttpBasedTransport",@"")];
}

- (void)send:(id <SRConnectionInterface>)connection withData:(NSString *)data completionHandler:(void (^)(id response))block {
    
    if (connection == nil) {
        [NSException raise:NSInvalidArgumentException format:NSLocalizedString(@"Connection should be non-null",@"")];
    }
    
    NSString *url = [connection.url stringByAppendingString:@"send"];
    url = [url stringByAppendingFormat:@"%@",[self sendQueryString:connection]];

    NSDictionary *postData = @{
        @"data" : data
    };
    
    SRLogHTTPTransport(@"will send data");
    
    [_httpClient post:url requestPreparer:^(id<SRRequest> request) {
        [connection prepareRequest:request];
    } postData:postData completionHandler:^(id<SRResponse> response) {
        NSString *raw = response.string;
        
        if (raw == nil || [raw isEqualToString:@""]) {
            return;
        }

        if(block) {
            block([raw SRJSONValue]);
        }
    }];
}

- (void)abort:(id <SRConnectionInterface>)connection {
    SRLogHTTPTransport(@"will stop transport");

    NSString *url = [connection.url stringByAppendingString:@"abort"];
    url = [url stringByAppendingFormat:@"%@",[self sendQueryString:connection]];
    
    [_httpClient post:url requestPreparer:^(id <SRRequest> request){ [connection prepareRequest:request]; } completionHandler:nil];
}

#pragma mark - 
#pragma mark Protected Helpers

//?transport=<transportname>&connectionToken=<connectionToken>&messageId=<messageId_or_Null>&groupsToken=<groupsToken>&connectionData=<data><customquerystring>
- (NSString *)receiveQueryString:(id <SRConnectionInterface>)connection data:(NSString *)data {
    NSMutableString *queryStringBuilder = [NSMutableString string];
    [queryStringBuilder appendFormat:@"?transport=%@",_transport];
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

    NSString *customQuery = [SRHttpBasedTransport getCustomQueryString:connection];
    
    if (customQuery != nil && ![customQuery isEqualToString:@""]) {
        [queryStringBuilder appendFormat:@"&%@",customQuery];
    }
    
    return queryStringBuilder;
}

//?transport=<transportname>&connectionToken=<connectionToken><customquerystring>
- (NSString *)sendQueryString:(id <SRConnectionInterface>)connection {
    return [NSString stringWithFormat:@"?transport=%@&connectionToken=%@%@",_transport,
            [connection.connectionToken stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
            [SRHttpBasedTransport getCustomQueryString:connection]];
}

- (void)processResponse:(id <SRConnectionInterface>)connection response:(NSString *)response timedOut:(BOOL *)timedOut disconnected:(BOOL *)disconnected {
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
            
            if (result[@"I"] != nil) {
                [connection didReceiveData:response];
                return;
            }
            
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

- (void)updateGroups:(id <SRConnectionInterface>)connection groupsToken:(NSString *)token {
    if (token != nil) {
        connection.groupsToken = token;
    }
}

+ (NSString *)getCustomQueryString:(id <SRConnectionInterface>)connection {
    return (connection.queryString == nil || [connection.queryString isEqualToString:@""] == YES) ? @"" : [@"&" stringByAppendingString:connection.queryString] ;
}

@end
