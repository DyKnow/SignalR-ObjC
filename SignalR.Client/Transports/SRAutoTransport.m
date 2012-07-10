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
#import "SRConnection.h"
#import "SRLongPollingTransport.h"
#import "SRServerSentEventsTransport.h"
#import "SRSignalRConfig.h"

@interface SRAutoTransport ()

// List of transports in fallback order
@property (strong, nonatomic, readonly) NSArray *transports;
@property (strong, nonatomic, readonly) id <SRClientTransport> transport;

- (void)resolveTransport:(SRConnection *)connection data:(NSString *)data taskCompletionSource:(void (^)(id response))block index:(int)index;

@end

@implementation SRAutoTransport

@synthesize httpClient = _httpClient;

@synthesize transports = _transports;
@synthesize transport = _transport;

- (id)initWithHttpClient:(id<SRHttpClient>)httpClient;
{
    if(self = [super init])
    {
        _httpClient = httpClient;
        _transports = [NSArray arrayWithObjects:[[SRServerSentEventsTransport alloc] init],[[SRLongPollingTransport alloc] init], nil];
    }
    return self;
}

- (void)negotiate:(SRConnection *)connection continueWith:(void (^)(SRNegotiationResponse *response))block
{
    [SRHttpBasedTransport getNegotiationResponse:_httpClient connection:connection continueWith:block];
}

- (void)start:(SRConnection *)connection withData:(NSString *)data continueWith:(void (^)(id response))block
{
    [self resolveTransport:connection data:data taskCompletionSource:block index:0];
}

- (void)resolveTransport:(SRConnection *)connection data:(NSString *)data taskCompletionSource:(void (^)(id response))block index:(int)index
{
    id <SRClientTransport> transport = [_transports objectAtIndex:index];
    
    [transport start:connection withData:data continueWith:^(id task) 
    {
        if (task != nil)
        {
#if DEBUG_AUTO_TRANSPORT || DEBUG_HTTP_BASED_TRANSPORT
            SR_DEBUG_LOG(@"[AUTO_TRANSPORT] will switch to next transport");
#endif
            int next = index + 1;
            if (next < [_transports count])
            {
                [self resolveTransport:connection data:data taskCompletionSource:block index:next];
            }
            else
            {
                NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
                [userInfo setObject:NSInternalInconsistencyException forKey:NSLocalizedFailureReasonErrorKey];
                [userInfo setObject:[NSString stringWithFormat:NSLocalizedString(@"No transport could be initialized successfully. Try specifying a different transport or none at all for auto initialization.",@"")] forKey:NSLocalizedDescriptionKey];
                NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:NSLocalizedString(@"com.SignalR-ObjC.%@",@""),NSStringFromClass([self class])] 
                                                     code:0 
                                                 userInfo:userInfo];
                [connection didReceiveError:error];
            }
        }
        else
        {
#if DEBUG_AUTO_TRANSPORT || DEBUG_HTTP_BASED_TRANSPORT
            SR_DEBUG_LOG(@"[AUTO_TRANSPORT] did set active transport");
#endif
            //Set the active transport
            _transport = transport;
             
            if(block) 
            {
                block(nil);
            }
        }
    }];
}

- (void)send:(SRConnection *)connection withData:(NSString *)data continueWith:(void (^)(id response))block
{
#if DEBUG_AUTO_TRANSPORT || DEBUG_HTTP_BASED_TRANSPORT
    SR_DEBUG_LOG(@"[AUTO_TRANSPORT] will send data from active transport");
#endif
    [_transport send:connection withData:data continueWith:block];
}

- (void)stop:(SRConnection *)connection
{
#if DEBUG_AUTO_TRANSPORT || DEBUG_HTTP_BASED_TRANSPORT
    SR_DEBUG_LOG(@"[AUTO_TRANSPORT] will stop transport");
#endif
    [_transport stop:connection];
}

- (void)dealloc
{
    _httpClient = nil;
    _transports = nil;
    _transport = nil;
}

@end
