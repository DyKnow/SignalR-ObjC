//
//  SRAutoTransport.m
//  SignalR
//
//  Created by Alex Billingsley on 1/15/12.
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

#import "SRAutoTransport.h"
#import "SRConnectionInterface.h"
#import "SRLog.h"
#import "SRLongPollingTransport.h"
#import "SRServerSentEventsTransport.h"

@interface SRAutoTransport ()

// List of transports in fallback order
@property (strong, nonatomic, readonly) NSArray *transports;
@property (strong, nonatomic, readonly) id <SRClientTransportInterface> transport;

- (void)resolveTransport:(id <SRConnectionInterface>)connection data:(NSString *)data taskCompletionSource:(void (^)(id response))block index:(int)index;

@end

@implementation SRAutoTransport

- (instancetype)initWithHttpClient:(id<SRHttpClient>)httpClient {
    if(self = [super init]) {
        _httpClient = httpClient;
        _transports = @[[[SRServerSentEventsTransport alloc] initWithHttpClient:httpClient],[[SRLongPollingTransport alloc] initWithHttpClient:httpClient]];
    }
    return self;
}

- (NSString *)name {
    if (self.transport == nil) return nil;
    return self.transport.name;
}

- (void)negotiate:(id <SRConnectionInterface>)connection completionHandler:(void (^)(SRNegotiationResponse *response))block {
    [SRHttpBasedTransport getNegotiationResponse:_httpClient connection:connection completionHandler:block];
}

- (void)start:(id <SRConnectionInterface>)connection withData:(NSString *)data completionHandler:(void (^)(id response))block {
    [self resolveTransport:connection data:data taskCompletionSource:block index:0];
}

- (void)resolveTransport:(id <SRConnectionInterface>)connection data:(NSString *)data taskCompletionSource:(void (^)(id response))block index:(int)index {
    id <SRClientTransportInterface> transport = _transports[index];
    
    [transport start:connection withData:data completionHandler:^(id task) {
        if (task != nil) {
            SRLogAutoTransport(@"will switch to next transport");

            // If that transport fails to initialize then fallback
            int next = index + 1;
            if (next < [_transports count]) {
                // Try the next transport
                [self resolveTransport:connection data:data taskCompletionSource:block index:next];
            } else {
                // If there's nothing else to try then just fail
                NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
                userInfo[NSLocalizedFailureReasonErrorKey] = NSInternalInconsistencyException;
                userInfo[NSLocalizedDescriptionKey] = [NSString stringWithFormat:NSLocalizedString(@"No transport could be initialized successfully. Try specifying a different transport or none at all for auto initialization.",@"")];
                NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:NSLocalizedString(@"com.SignalR-ObjC.%@",@""),NSStringFromClass([self class])] 
                                                     code:0 
                                                 userInfo:userInfo];
                [connection didReceiveError:error];
            }
        } else {
            SRLogAutoTransport(@"did set active transport");
            
            //Set the active transport
            _transport = transport;
             
            if(block) 
            {
                block(nil);
            }
        }
    }];
}

- (void)send:(id <SRConnectionInterface>)connection withData:(NSString *)data completionHandler:(void (^)(id response))block {
    SRLogAutoTransport(@"will send data from active transport");

    [_transport send:connection withData:data completionHandler:block];
}

- (void)abort:(id <SRConnectionInterface>)connection {
    SRLogAutoTransport(@"will stop transport");

    [_transport abort:connection];
}

@end
