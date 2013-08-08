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

#import "AFHTTPRequestOperation.h"
#import "SRAutoTransport.h"
#import "SRConnectionInterface.h"
#import "SRLog.h"
#import "SRLongPollingTransport.h"
#import "SRNegotiationResponse.h"
#import "SRServerSentEventsTransport.h"
#import "SRWebSocketTransport.h"

@interface SRAutoTransport ()

@property (strong, nonatomic, readwrite) id <SRClientTransportInterface> transport;
// List of transports in fallback order
@property (strong, nonatomic, readonly) NSArray *transports;
@property (assign, nonatomic, readwrite) int startIndex;

@end

@implementation SRAutoTransport

- (instancetype)init {
    NSArray *transports = @[[[SRWebSocketTransport alloc] init],
                            [[SRServerSentEventsTransport alloc] init],
                            [[SRLongPollingTransport alloc] init]];
    return [self initWithTransports:transports];
}

- (instancetype)initWithTransports:(NSArray *)transports {
    if(self = [super init]) {
        _transports = transports;
        _startIndex = 0;
    }
    return self;
}

#pragma mark
#pragma mark SRClientTransportInterface

- (NSString *)name {
    if (self.transport == nil) return nil;
    return self.transport.name;
}

- (BOOL)supportsKeepAlive {
    if (self.transport == nil) return NO;
    return self.transport.supportsKeepAlive;
}

- (void)negotiate:(id <SRConnectionInterface>)connection completionHandler:(void (^)(SRNegotiationResponse *response))block {
    __weak __typeof(&*self)weakSelf = self;
    [super negotiate:connection completionHandler:^(SRNegotiationResponse *response) {
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        if (![response tryWebSockets]) {
            strongSelf.startIndex = 1;
        }
        
        if (block) {
            block(response);
        }
    }];
}

- (void)start:(id <SRConnectionInterface>)connection data:(NSString *)data completionHandler:(void (^)(id response))block {
    [self start:connection data:data transportIndex:self.startIndex completionHandler:block];
}

- (void)start:(id <SRConnectionInterface>)connection data:(NSString *)data transportIndex:(int)index completionHandler:(void (^)(id response))block  {
    __weak id <SRClientTransportInterface> transport = self.transports[index];
    
    __weak __typeof(&*self)weakSelf = self;
    __weak __typeof(&*connection)weakConnection = connection;
    [transport start:connection data:data completionHandler:^(id response) {
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        __strong __typeof(&*transport)strongTransport = transport;

        if ([response isKindOfClass:[NSError class]]) {
            SRLogAutoTransport(@"will switch to next transport");
            
            // If that transport fails to initialize then fallback
            int next = index + 1;
            if (next < [strongSelf.transports count]) {
                // Try the next transport
                [strongSelf start:strongConnection data:data transportIndex:next completionHandler:block];
            } else {
                // If there's nothing else to try then just fail
                NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
                userInfo[NSLocalizedFailureReasonErrorKey] = NSInternalInconsistencyException;
                userInfo[NSLocalizedDescriptionKey] = [NSString stringWithFormat:NSLocalizedString(@"No transport could be initialized successfully. Try specifying a different transport or none at all for auto initialization.",@"")];
                NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:NSLocalizedString(@"com.SignalR-ObjC.%@",@""),NSStringFromClass([strongSelf class])]
                                                     code:0
                                                 userInfo:userInfo];
                [strongConnection didReceiveError:error];
            }
        } else {
            SRLogAutoTransport(@"did set active transport");
            
            //Set the active transport
            strongSelf.transport = strongTransport;
            
            if(block) {
                block(nil);
            }
        }
    }];
}

- (void)send:(id <SRConnectionInterface>)connection data:(NSString *)data completionHandler:(void (^)(id response))block {
    SRLogAutoTransport(@"will send data from active transport");
    [self.transport send:connection data:data completionHandler:block];
}

- (void)lostConnection:(id<SRConnectionInterface>)connection {
    SRLogAutoTransport(@"lost connection");
    [self.transport lostConnection:connection];
}

- (void)abort:(id <SRConnectionInterface>)connection timeout:(NSNumber *)timeout {
    SRLogAutoTransport(@"will stop transport");
    [self.transport abort:connection timeout:timeout];
}

@end
