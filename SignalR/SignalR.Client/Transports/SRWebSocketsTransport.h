//
//  SRWebSocketsTransport.h
//  SignalR
//
//  Created by Alex Billingsley on 10/24/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SRClientTransport.h"
#import "SRWebSocket.h"

@interface SRWebSocketsTransport : NSObject <SRClientTransport, SRWebSocketDelegate>

@property (nonatomic, retain) SRWebSocket *socket;

- (void)start:(SRConnection *)connection;
- (void)send:(SRConnection *)connection withData:(NSString *)data;
- (void)stop:(SRConnection *)connection;

@end