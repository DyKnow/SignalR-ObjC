//
//  SRClientTransport.h
//  SignalR
//
//  Created by Alex Billingsley on 10/28/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SRConnection;
/**
 * IClientTransport
 * Each Client Transport should conform to the following protocol
 **/
@protocol SRClientTransport <NSObject>

- (void)start:(SRConnection *)connection withData:(NSString *)data;
- (void)send:(SRConnection *)connection withData:(NSString *)data onCompletion:(void(^)(id))block;
- (void)stop:(SRConnection *)connection;

@end

#pragma  mark - Transport Constants

#define kConnectEndPoint @"connect"
#define kSendEndPoint @"send"

#pragma  mark - Request Constants

#define kConnectionData @"connectionData"
#define kData @"data"
#define kMessageId @"messageId"
#define kConnectionId @"connectionId"
#define kTransport @"transport"
#define kGroups @"groups"

#pragma  mark - Response Constants

#define kResponse_MessageId @"MessageId"
#define kResponse_Messages @"Messages"
#define kResponse_TransportData @"TransportData"
#define kResponse_Groups @"Groups"
#define kResponse_LongPollDelay @"LongPollDelay"