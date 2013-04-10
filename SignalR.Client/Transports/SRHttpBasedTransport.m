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
#import "SRTransportHelper.h"
#import "NSObject+SRJSON.h"

@interface SRHttpBasedTransport()

@property (strong, nonatomic, readonly) NSString *transport;

- (NSString *)sendQueryString:(id <SRConnectionInterface>)connection;

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
    [SRTransportHelper getNegotiationResponse:_httpClient connection:connection completionHandler:block];
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
    url = [url stringByAppendingString:[self sendQueryString:connection]];

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
        
        [connection didReceiveData:raw];

        if(block) {
            block([raw SRJSONValue]);
        }
    }];
}

- (void)abort:(id <SRConnectionInterface>)connection {
    SRLogHTTPTransport(@"will stop transport");

    NSString *url = [connection.url stringByAppendingString:@"abort"];
    url = [url stringByAppendingString:[self sendQueryString:connection]];
    
    [_httpClient post:url requestPreparer:^(id <SRRequest> request){ [connection prepareRequest:request]; } completionHandler:nil];
}

#pragma mark - 
#pragma mark Protected Helpers

- (NSString *)receiveQueryString:(id <SRConnectionInterface>)connection data:(NSString *)data {
    return [SRTransportHelper receiveQueryString:connection data:data transport:_transport];
}

//?transport=<transportname>&connectionToken=<connectionToken><customquerystring>
- (NSString *)sendQueryString:(id <SRConnectionInterface>)connection {
    NSString *customQueryString = (connection.queryString == nil || [connection.queryString isEqualToString:@""]) ? @"" : [@"&" stringByAppendingString:connection.queryString];
    return [NSString stringWithFormat:@"?transport=%@&connectionToken=%@%@",_transport,
            [connection.connectionToken stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
            customQueryString];
}

@end
