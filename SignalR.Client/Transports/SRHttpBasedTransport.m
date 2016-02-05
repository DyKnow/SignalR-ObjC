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

#import <AFNetworking/AFNetworking.h>
#import "SRConnectionInterface.h"
#import "SRHttpBasedTransport.h"
#import "SRLog.h"
#import "SRNegotiationResponse.h"

#import "NSObject+SRJSON.h"

@interface SRHttpBasedTransport()

@property (assign, nonatomic, readwrite) BOOL startedAbort;

@end

@implementation SRHttpBasedTransport

#pragma mark
#pragma mark SRClientTransportInterface

- (NSString *)name {
    return @"";
}

- (BOOL)supportsKeepAlive {
    return NO;
}

- (void)negotiate:(id<SRConnectionInterface>)connection connectionData:(NSString *)connectionData completionHandler:(void (^)(SRNegotiationResponse * response, NSError *error))block {
    
    id parameters = [self connectionParameters:connection connectionData:connectionData];
    
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET" URLString:[connection.url stringByAppendingString:@"negotiate"] parameters:parameters error:nil];
    [connection prepareRequest:request]; //TODO: prepareRequest
    [request setTimeoutInterval:30];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setResponseSerializer:[AFJSONResponseSerializer serializer]];
    //operation.shouldUseCredentialStorage = self.shouldUseCredentialStorage;
    //operation.credential = self.credential;
    //operation.securityPolicy = self.securityPolicy;
    SRLogTransportDebug(@"will negotiate at url: %@", [[request URL] absoluteString]);
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        SRLogTransportInfo(@"negotiate was successful %@", responseObject);
        if(block) {
            block([[SRNegotiationResponse alloc] initWithDictionary:responseObject], nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        SRLogTransportError(@"negotiate failed %@", error);
        if(block) {
            block(nil, error);
        }
    }];
    [operation start];
}

- (void)start:(id<SRConnectionInterface>)connection connectionData:(NSString *)connectionData completionHandler:(void (^)(id response, NSError *error))block {
}

- (void)send:(id<SRConnectionInterface>)connection data:(NSString *)data connectionData:(NSString *)connectionData completionHandler:(void (^)(id response, NSError *error))block {
    
    id parameters = [self connectionParameters:connection connectionData:connectionData];
    
    //TODO: this is a little strange but SignalR Expects the parameters in the queryString and fails if in the body.
    //So we let AFNetworking Generate our URL with proper encoding and then create the POST url which will encode the data in the body.
    NSMutableURLRequest *url = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET" URLString:[connection.url stringByAppendingString:@"send"] parameters:parameters error:nil];
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"POST" URLString:[[url URL] absoluteString] parameters:@{ @"data" : data } error:nil];
    [connection prepareRequest:request]; //TODO: prepareRequest
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setResponseSerializer:[AFJSONResponseSerializer serializer]];
    //operation.shouldUseCredentialStorage = self.shouldUseCredentialStorage;
    //operation.credential = self.credential;
    //operation.securityPolicy = self.securityPolicy;
    SRLogTransportDebug(@"will send at url: %@", [[request URL] absoluteString]);
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        SRLogTransportInfo(@"send was successful %@", responseObject);
        [connection didReceiveData:responseObject];
        if(block) {
            block(responseObject, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        SRLogTransportError(@"send failed %@", error);
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

//@parameter: timeout, the amount of time we
- (void)abort:(id<SRConnectionInterface>)connection timeout:(NSNumber *)timeout connectionData:(NSString *)connectionData {

    if (timeout <= 0) {
        SRLogTransportWarn(@"stopping transport without informing server");
        return;
    }
    
    // Ensure that an abort request is only made once
    if (!_startedAbort)
    {
        _startedAbort = YES;
        
        id parameters = [self connectionParameters:connection connectionData:connectionData];
        
        NSMutableURLRequest *url = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET" URLString:[connection.url stringByAppendingString:@"abort"] parameters:parameters error:nil];
        NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"POST" URLString:[[url URL] absoluteString] parameters:nil error:nil];
        [connection prepareRequest:request]; //TODO: prepareRequest
        [request setTimeoutInterval:2];
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        [operation setResponseSerializer:[AFJSONResponseSerializer serializer]];
        //operation.shouldUseCredentialStorage = self.shouldUseCredentialStorage;
        //operation.credential = self.credential;
        //operation.securityPolicy = self.securityPolicy;
        SRLogTransportDebug(@"will abort at url: %@", [[request URL] absoluteString]);
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            SRLogTransportInfo(@"abort was successful %@", responseObject);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            SRLogTransportError(@"abort failed %@",error);
            [self completeAbort];
        }];
        [operation start];
    }
}

- (NSDictionary *)connectionParameters:(id <SRConnectionInterface>)connection connectionData:(NSString *)connectionData {
    NSDictionary *parameters = @{};
    parameters = [self addClientProtocol:parameters connection:connection];
    parameters = [self addTransport:parameters transport:[self name]];
    parameters = [self addConnectionData:parameters connectionData:connectionData];
    parameters = [self addConnectionToken:parameters connection:connection];
    parameters = [self addQueryString:parameters connection:connection];
    
    return parameters;
}

- (NSDictionary *)addClientProtocol:(NSDictionary *)parameters connection:(id <SRConnectionInterface>)connection {
    if ([connection protocol]) {
        NSMutableDictionary *_parameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
        [_parameters addEntriesFromDictionary:@{
            @"clientProtocol" : [connection protocol]
        }];
        return _parameters;
    }
    return parameters;
}

- (NSDictionary *)addTransport:(NSDictionary *)parameters transport:(NSString *)transport {
    if (transport) {
        NSMutableDictionary *_parameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
        [_parameters addEntriesFromDictionary:@{
            @"transport" : transport
        }];
        return _parameters;
    }
    return parameters;
}

- (NSDictionary *)addConnectionData:(NSDictionary *)parameters connectionData:(NSString *)connectionData {
    if (connectionData) {
        NSMutableDictionary *_parameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
        [_parameters addEntriesFromDictionary:@{
            @"connectionData" : connectionData
        }];
        return _parameters;
    }
    return parameters;
}

- (NSDictionary *)addConnectionToken:(NSDictionary *)parameters connection:(id <SRConnectionInterface>)connection {
    if ([connection connectionToken]) {
        NSMutableDictionary *_parameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
        [_parameters addEntriesFromDictionary:@{
            @"connectionToken" : [connection connectionToken]
        }];
        return _parameters;
    }
    return parameters;
}

- (NSDictionary *)addQueryString:(NSDictionary *)parameters connection:(id <SRConnectionInterface>)connection {
    if ([connection queryString]) {
        NSMutableDictionary *_parameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
        [_parameters addEntriesFromDictionary:[connection queryString]];
        return _parameters;
    }
    return parameters;
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
        
        NSString *groupsToken = result[@"G"];
        if (groupsToken) {
            connection.groupsToken = groupsToken;
        }
        
        id messages = result[@"M"];
        if(messages && [messages isKindOfClass:[NSArray class]]) {
            connection.messageId = result[@"C"];
            
            for (id message in messages) {
                [connection didReceiveData:message];
            }
            
            if ([result[@"S"] boolValue]) {
                //TODO: Call Initialized Callback
                //onInitialized();
            }
        }
    }
}

@end
