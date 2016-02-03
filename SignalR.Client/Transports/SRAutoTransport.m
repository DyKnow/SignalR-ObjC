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
#import "SRNegotiationResponse.h"
#import "SRServerSentEventsTransport.h"
#import "SRWebSocketTransport.h"

static NSString *const kBestTransportIndex = @"kBestTransportIndex";

@interface SRAutoTransport ()

@property (strong, nonatomic, readwrite) id <SRClientTransportInterface> transport;
// List of transports in fallback order
@property (strong, nonatomic, readonly) NSMutableArray *transports;

@end

@implementation SRAutoTransport

- (instancetype)init {
    NSArray *transports = @[[[SRWebSocketTransport alloc] init],
                            [[SRServerSentEventsTransport alloc] init],
                            [[SRLongPollingTransport alloc] init]];
    return [self initWithTransports:[NSMutableArray arrayWithArray:transports]];
}

- (instancetype)initWithTransports:(NSMutableArray *)transports {
    if(self = [super init]) {
        _transports = transports;
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

- (void)negotiate:(id<SRConnectionInterface>)connection connectionData:(NSString *)connectionData completionHandler:(void (^)(SRNegotiationResponse *, NSError *))block {
    __weak __typeof(&*self)weakSelf = self;
    [super negotiate:connection connectionData:connectionData completionHandler:^(SRNegotiationResponse *response, NSError *error) {
        if(!error) {
            __strong __typeof(&*weakSelf)strongSelf = weakSelf;
            if (![response tryWebSockets]) {
                NSIndexSet *invalidTransports = [strongSelf.transports indexesOfObjectsPassingTest:^BOOL(id <SRClientTransportInterface> transport, NSUInteger idx, BOOL *stop) {
                    return [transport.name isEqualToString:@"webSockets"];
                }];
                [strongSelf.transports removeObjectsAtIndexes:invalidTransports];
            }
        }
        if (block) {
            block(response, error);
        }
    }];
}

- (void)start:(id<SRConnectionInterface>)connection connectionData:(NSString *)connectionData completionHandler:(void (^)(id response, NSError *error))block {
    int transportIndex = [self bestTransportIndex];
    [self start:connection connectionData:connectionData transportIndex:transportIndex completionHandler:block];
}

- (void)start:(id <SRConnectionInterface>)connection connectionData:(NSString *)connectionData transportIndex:(int)index completionHandler:(void (^)(id response, NSError *error))block  {
    __weak __typeof(&*self)weakSelf = self;
    __weak __typeof(&*connection)weakConnection = connection;
    __weak id <SRClientTransportInterface> transport = self.transports[index];
    [transport start:connection connectionData:connectionData completionHandler:^(id response, NSError *error) {
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        __strong __typeof(&*transport)strongTransport = transport;

        if (error) {
            SRLogAutoTransport(@"will switch to next transport");
            
            // If that transport fails to initialize then fallback
            /*
             First try the best transport index to get minimum connection time, if it fails then try other
             transport layers untill you have tried every transport or get a success.
             */
            int next = (index + 1)%[strongSelf.transports count];
            // If next equals bestTransportIndex it means we have tried all
            if (next != [strongSelf bestTransportIndex]) {
                // Try the next transport
                [strongSelf start:strongConnection connectionData:connectionData transportIndex:next completionHandler:block];
            } else {
                // If there's nothing else to try then just fail
                NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
                userInfo[NSLocalizedFailureReasonErrorKey] = NSInternalInconsistencyException;
                userInfo[NSLocalizedDescriptionKey] = [NSString stringWithFormat:NSLocalizedString(@"No transport could be initialized successfully. Try specifying a different transport or none at all for auto initialization.",@"")];
                NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:NSLocalizedString(@"com.SignalR.SignalR-ObjC.%@",@""),NSStringFromClass([strongSelf class])]
                                                     code:0
                                                 userInfo:userInfo];
                
                if(block) {
                    block(nil, error);
                }
            }
        } else {
            /*
             Once you get your best transport index, save it so that
             next time you directly use this particular transport instead
             try others every time.
             */
            [strongSelf setBestTransportIndex:index];
            SRLogAutoTransport(@"did set active transport");
            
            //Set the active transport
            strongSelf.transport = strongTransport;
            
            if(block) {
                block(nil, nil);
            }
        }
    }];
}


- (void)send:(id <SRConnectionInterface>)connection data:(NSString *)data connectionData:(NSString *)connectionData completionHandler:(void (^)(id response, NSError *error))block {
    SRLogAutoTransport(@"will send data from active transport");
    [self.transport send:connection data:data connectionData:connectionData completionHandler:block];
}

- (void)lostConnection:(id<SRConnectionInterface>)connection {
    SRLogAutoTransport(@"lost connection");
    [self.transport lostConnection:connection];
}

- (void)abort:(id <SRConnectionInterface>)connection timeout:(NSNumber *)timeout connectionData:(NSString *)connectionData {
    SRLogAutoTransport(@"will stop transport");
    [self.transport abort:connection timeout:timeout connectionData:connectionData];
}

#pragma mark - Best Transport index
/**
 Saves the best transport layer index User Defaults so that you can
 use it later on
 @param index Best transport index in array 'transports'
 */
-(void)setBestTransportIndex:(int)index{
    NSNumber *number = [NSNumber numberWithInt:index];
    [[NSUserDefaults standardUserDefaults] setValue:number forKey:kBestTransportIndex];
}
/**
 Retrieve the best transport index from User Defaults
 @return index Best transport index in array 'transports'
 */
-(int)bestTransportIndex{
    NSNumber *number = [[NSUserDefaults standardUserDefaults] valueForKey:kBestTransportIndex];
    if (number && number.intValue < self.transports.count) {
        return number.intValue;
    }
    return 0;
}

@end
