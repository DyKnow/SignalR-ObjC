//
//  SRServerSentEventsTransport.m
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
#import "SRServerSentEventsTransport.h"
#import "SRConnectionInterface.h"
#import "SREventSourceStreamReader.h"
#import "SRExceptionHelper.h"
#import "SRConnectionExtensions.h"
#import "SRLog.h"
#import "SRChunkBuffer.h"
#import "SRServerSentEvent.h"
#import "SREventSourceRequestSerializer.h"
#import "SREventSourceResponseSerializer.h"

typedef void (^SRCompletionHandler)(id response, NSError *error);

@interface SRServerSentEventsTransport ()

@property (assign) BOOL stop;
@property (strong, nonatomic, readwrite) SREventSourceStreamReader *eventSource;
@property (strong, nonatomic, readwrite) NSOperationQueue *serverSentEventsOperationQueue;
@property (copy) SRCompletionHandler completionHandler;
@property (strong, nonatomic, readwrite) NSBlockOperation * connectTimeoutOperation;
@end

@implementation SRServerSentEventsTransport

- (instancetype)init {
    if (self = [super init]) {
        _serverSentEventsOperationQueue = [[NSOperationQueue alloc] init];
        [_serverSentEventsOperationQueue setMaxConcurrentOperationCount:1];
        _reconnectDelay = @2;
    }
    return self;
}

#pragma mark
#pragma mark SRClientTransportInterface

- (NSString *)name {
    return @"serverSentEvents";
}

- (BOOL)supportsKeepAlive {
    return YES;
}

- (void)negotiate:(id<SRConnectionInterface>)connection connectionData:(NSString *)connectionData completionHandler:(void (^)(SRNegotiationResponse * response, NSError *error))block {
    SRLogSSEDebug(@"serverSentEvents will negotiate");
    [super negotiate:connection connectionData:connectionData completionHandler:nil];
}

- (void)start:(id<SRConnectionInterface>)connection connectionData:(NSString *)connectionData completionHandler:(void (^)(id response, NSError *error))block {
    SRLogSSEDebug(@"serverSentEvents will connect with connectionData %@", connectionData);
    
    self.completionHandler = block;
    
    __weak __typeof(&*self)weakSelf = self;
    self.connectTimeoutOperation = [NSBlockOperation blockOperationWithBlock:^{
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        if (strongSelf.completionHandler) {
            NSDictionary* userInfo = @{
                NSLocalizedDescriptionKey: NSLocalizedString(@"Connection timed out.", nil),
                NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Connection did not receive initialized message before the timeout.", nil),
                NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Retry or switch transports.", nil)
                                       };
            NSError *timeout = [[NSError alloc]initWithDomain:[NSString stringWithFormat:NSLocalizedString(@"com.SignalR.SignalR-ObjC.%@",@""),NSStringFromClass([self class])] code:NSURLErrorTimedOut userInfo:userInfo];
            SRLogSSEError(@"serverSentEvents failed to receive initialized message before timeout");
            strongSelf.completionHandler(nil, timeout);
            strongSelf.completionHandler = nil;
        }
    }];
    [self.connectTimeoutOperation performSelector:@selector(start) withObject:nil afterDelay:[[connection transportConnectTimeout] integerValue]];
    
    [self open:connection connectionData:connectionData isReconnecting:NO];
}

- (void)send:(id<SRConnectionInterface>)connection data:(NSString *)data connectionData:(NSString *)connectionData completionHandler:(void (^)(id response, NSError *error))block {
    SRLogSSEDebug(@"serverSentEvents will send data %@", data);
    [super send:connection data:data connectionData:connectionData completionHandler:block];
}

- (void)abort:(id<SRConnectionInterface>)connection timeout:(NSNumber *)timeout connectionData:(NSString *)connectionData {
    SRLogSSEDebug(@"serverSentEvents will abort");
    _stop = YES;
    [self.serverSentEventsOperationQueue cancelAllOperations];//this will enqueue a failure on run loop
    [super abort:connection timeout:timeout connectionData:connectionData];//we expect this to set stop to YES
}

- (void)lostConnection:(id<SRConnectionInterface>)connection {
    SRLogSSEWarn(@"serverSentEvents lost connection, cancelling connection");
    [self.serverSentEventsOperationQueue cancelAllOperations];
}

#pragma mark -
#pragma mark SSE Transport

- (void)open:(id <SRConnectionInterface>)connection connectionData:(NSString *)connectionData isReconnecting: (BOOL) isReconnecting {
    id parameters = @{
        @"transport" : [self name],
        @"connectionToken" : ([connection connectionToken]) ? [connection connectionToken] : @"",
        @"messageId" : ([connection messageId]) ? [connection messageId] : @"",
        @"groupsToken" : ([connection groupsToken]) ? [connection groupsToken] : @"",
        @"connectionData" : (connectionData) ? connectionData : @"",
    };
    
    if ([connection queryString]) {
        NSMutableDictionary *_parameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
        [_parameters addEntriesFromDictionary:[connection queryString]];
        parameters = _parameters;
    }
    
    NSString *url = isReconnecting ?
        [connection.url stringByAppendingString:@"reconnect"] :
        [connection.url stringByAppendingString:@"connect"];
    
    __weak __typeof(&*self)weakSelf = self;
    __weak __typeof(&*connection)weakConnection = connection;
    NSMutableURLRequest *request = [[SREventSourceRequestSerializer serializer] requestWithMethod:@"GET" URLString:url parameters:parameters error:nil];
    [connection prepareRequest:request]; //TODO: prepareRequest
    [request setTimeoutInterval:240];
    [request setValue:@"Keep-Alive" forHTTPHeaderField:@"Connection"];
    //TODO: prepareRequest
    
    SRLogSSEDebug(@"serverSentEvents will connect at url: %@", [[request URL] absoluteString]);
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setResponseSerializer:[SREventSourceResponseSerializer serializer]];
    //operation.shouldUseCredentialStorage = self.shouldUseCredentialStorage;
    //operation.credential = self.credential;
    //operation.securityPolicy = self.securityPolicy;
    _eventSource = [[SREventSourceStreamReader alloc] initWithStream:operation.outputStream];
    _eventSource.opened = ^() {
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        SRLogSSEInfo(@"serverSentEvents did open eventSource");
        
        // This will noop if we're not in the reconnecting state
        if([strongConnection changeState:reconnecting toState:connected]) {
            // Raise the reconnect event if the connection comes back up
            [strongConnection didReconnect];
        }
    };
    _eventSource.message = ^(SRServerSentEvent * sseEvent) {
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        
        if([sseEvent.event isEqual:@"data"]) {
            NSString *data = [[NSString alloc] initWithData:sseEvent.data encoding:NSUTF8StringEncoding];
            SRLogSSEInfo(@"serverSentEvents did receive: %@", data);
            if([data caseInsensitiveCompare:@"initialized"] == NSOrderedSame) {
                return;
            }
            
            BOOL shouldReconnect = NO;
            BOOL disconnect = NO;
            [strongSelf processResponse:strongConnection response:data shouldReconnect:&shouldReconnect disconnected:&disconnect];
            if (strongSelf.completionHandler) {
                [NSObject cancelPreviousPerformRequestsWithTarget:strongSelf.connectTimeoutOperation
                                                         selector:@selector(start)
                                                           object:nil];
                strongSelf.connectTimeoutOperation = nil;
                
                strongSelf.completionHandler(nil, nil);
                strongSelf.completionHandler = nil;
            }
            
            if(disconnect) {
                SRLogSSEDebug(@"serverSentEvents did receive disconnect command from server");
                _stop = YES;
                [strongConnection disconnect];
            }
        }
    };
    _eventSource.closed = ^(NSError *exception) { //server ended without error
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        
        SRLogSSEWarn(@"serverSentEvents eventSource did close with error %@", exception);
        
        if (exception != nil ){
            // Check if the request is aborted
            BOOL isRequestAborted = [SRExceptionHelper isRequestAborted:exception];
            
            if (!isRequestAborted) {
                // Don't raise exceptions if the request was aborted (connection was stopped).
                [strongConnection didReceiveError:exception];
            }
        }
        
        //release eventSource, no other scopes have access, would like to release before
        //eventSource will be nil for this scope before reconnect can call open, even if
        //it wasn't doing a timeout first
        _eventSource = nil;
        
        if (strongSelf.stop) {
            [strongSelf completeAbort];
        }
        else if ([strongSelf tryCompleteAbort]) {
        }
        else {
            [strongSelf reconnect:strongConnection data:connectionData];
        }
    };
    [_eventSource start];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        SRLogSSEWarn(@"serverSentEvents did complete");
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        if (strongSelf.stop) {
            [strongSelf completeAbort];
        } else if ([strongSelf tryCompleteAbort]) {
        } else {
            [strongSelf reconnect:strongConnection data:connectionData];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        SRLogSSEError(@"serverSentEvents did fail with error %@", error);
        
        //a little tough to read, but failure is mutually exclusive to open, message, or closed above
        //also, you may start in the received above and end up in the failure case
        //http://cocoadocs.org/docsets/AFNetworking/2.5.4/Classes/AFHTTPRequestOperation.html
        //we however do close the eventSource below, which will lead us to the above code
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        if (strongSelf.completionHandler) {//this is equivalent to the !reconnecting onStartFailed from c#
            SRLogSSEDebug(@"serverSentEvents did fail while connecting");
            [NSObject cancelPreviousPerformRequestsWithTarget:self.connectTimeoutOperation
                                                     selector:@selector(start)
                                                       object:nil];
            self.connectTimeoutOperation = nil;
            
            strongSelf.completionHandler(nil, error);
            strongSelf.completionHandler = nil;
        } else if (!isReconnecting){//failure should first attempt to reconect
            SRLogSSEWarn(@"will reconnect from errors: %@", error);
        } else {//failure while reconnecting should error
            //special case differs from above
            SRLogSSEError(@"error: %@", error);
            [operation cancel];//clean up to avoid duplicates
            [strongSelf.eventSource close: error];//clean up -> this should end up in eventSource.closed above
            return;//bail out early as we've taken care of the below
        }
        [operation cancel];//clean up to avoid duplicates
        [strongSelf.eventSource close];//clean up -> this should end up in eventSource.closed above
    }];
    [self.serverSentEventsOperationQueue addOperation:operation];
}

- (void)reconnect:(id <SRConnectionInterface>)connection data:(NSString *)data {
    __weak __typeof(&*self)weakSelf = self;
    __weak __typeof(&*connection)weakConnection = connection;
    SRLogSSEDebug(@"will reconnect in %@", self.reconnectDelay);
    [[NSBlockOperation blockOperationWithBlock:^{
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        __strong __typeof(&*weakConnection)strongConnection = weakConnection;
        
        if (connection.state != disconnected && [SRConnection ensureReconnecting:strongConnection]) {
            SRLogSSEWarn(@"reconnecting");
            [strongSelf.serverSentEventsOperationQueue cancelAllOperations];
            //now that all the current connections are tearing down, we have the queue to ourselves
            [strongSelf open:strongConnection connectionData:data isReconnecting:YES];
        }
        
    }] performSelector:@selector(start) withObject:nil afterDelay:[self.reconnectDelay integerValue]];
}

- (BOOL)isConnectionReconnecting:(id<SRConnectionInterface>)connection {
    return connection.state == reconnecting;
}

@end
