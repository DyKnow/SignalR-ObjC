//
//  SRLongPollingTransport.h
//  SignalR
//
//  Created by Alex Billingsley on 10/17/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRClientTransport.h"
#import "HttpHelper.h"
#import "NSString+Url.h"
#import "SBJson.h"

@interface SRLongPollingTransport : NSObject <SRClientTransport>

- (void)start:(SRConnection *)connection;
- (void)send:(SRConnection *)connection withData:(NSString *)data onCompletion:(void(^)(SRConnection *, id))block;
- (void)stop:(SRConnection *)connection;

@end