//
//  SRWebSocketsTransport.h
//  SignalR
//
//  Created by Alex Billingsley on 10/24/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRClientTransport.h"

@interface SRWebSocketsTransport : NSObject <SRClientTransport>

- (void)start:(SRConnection *)connection;
- (void)send:(SRConnection *)connection withData:(NSString *)data onCompletion:(void(^)(SRConnection *, id))block;
- (void)stop:(SRConnection *)connection;

@end