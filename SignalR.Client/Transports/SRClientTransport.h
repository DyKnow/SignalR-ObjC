//
//  SRClientTransport.h
//  SignalR
//
//  Created by Alex Billingsley on 10/28/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SRConnection;
@class SRHttpResponse;

/**
 * IClientTransport
 * Each Client Transport should conform to the following protocol
 **/
@protocol SRClientTransport <NSObject>

- (void)start:(SRConnection *)connection withData:(NSString *)data continueWith:(void(^)(id))block;
- (void)send:(SRConnection *)connection withData:(NSString *)data continueWith:(void (^)(SRHttpResponse *response))block;
- (void)stop:(SRConnection *)connection;

@end