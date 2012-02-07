//
//  SRClientTransport+Constants.h
//  SignalR.Samples
//
//  Created by Alex Billingsley on 1/25/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SRClientTransport.h"

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
#define kResponse_TimedOut @"TimedOut"
#define kResponse_Disconnected @"Disconnected"