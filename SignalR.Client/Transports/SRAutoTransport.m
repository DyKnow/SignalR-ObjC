//
//  SRAutoTransport.m
//  SignalR
//
//  Created by Alex Billingsley on 1/15/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import "SRAutoTransport.h"
#import "SRSignalRConfig.h"

#import "SRTransport.h"

@interface SRAutoTransport ()

@property (strong, nonatomic, readonly) NSArray *transports;
@property (strong, nonatomic, readonly) id <SRClientTransport> transport;

- (void)resolveTransport:(SRConnection *)connection data:(NSString *)data taskCompletionSource:(void (^)(id))block index:(int)index;

@end

@implementation SRAutoTransport

@synthesize transports = _transports;
@synthesize transport = _transport;

- (id)init
{
    if(self = [super init])
    {
        //List the transports in fallback order
        _transports = [NSArray arrayWithObjects:[SRTransport ServerSentEvents],[SRTransport LongPolling], nil];
    }
    return self;
}

- (void)start:(SRConnection *)connection withData:(NSString *)data continueWith:(void (^)(id))block
{
    [self resolveTransport:connection data:data taskCompletionSource:block index:0];
}

- (void)resolveTransport:(SRConnection *)connection data:(NSString *)data taskCompletionSource:(void (^)(id))block index:(int)index
{
    id <SRClientTransport> transport = [_transports objectAtIndex:index];
    
    [transport start:connection withData:data continueWith:
     ^(id task) {
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
                 [NSException raise:@"TransportInitializeException" format:@"No transport could be initialized successfully. Try specifying a different transport or none at all for auto initialization."];
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
    [_transport send:connection withData:data continueWith:block];
}

- (void)stop:(SRConnection *)connection
{
    [_transport stop:connection];
}

- (void)dealloc
{
    _transports = nil;
    _transport = nil;
}

@end
