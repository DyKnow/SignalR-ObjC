//
//  SRAutoTransport.m
//  SignalR
//
//  Created by Alex Billingsley on 1/15/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import "SRAutoTransport.h"

#import "SRTransport.h"

@interface SRAutoTransport ()

@property (strong, nonatomic, readonly) NSArray *transports;
@property (strong, nonatomic, readonly) id <SRClientTransport> transport;

- (void)resolveTransport:(SRConnection *)connection data:(NSString *)data index:(int)index;

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
    [self resolveTransport:connection data:data index:0];
}

- (void)resolveTransport:(SRConnection *)connection data:(NSString *)data index:(int)index
{
    id <SRClientTransport> transport = [_transports objectAtIndex:index];
    
    [transport start:connection withData:data continueWith:
     ^(id task) {
         NSLog(@"Contine Task");
     }];
    /*continueWith
    {
        if (task.isFaulted)
        {
            int next = index + 1;
            if (next < [_transports count])
            {
                [self resolveTransport:connection data:data index:next];
            }
            else
            {
                tcs.setException(task.exception);
            }
        }
        else
        {
            //Set the active transport
            _transport = transport;
            
            tcs.setResult(nil);
        }
    }*/
}

- (void)send:(SRConnection *)connection withData:(NSString *)data continueWith:(void (^)(id))block
{
    [_transport send:connection withData:data continueWith:block];
}

- (void)stop:(SRConnection *)connection
{
    [_transport stop:connection];
}
@end
