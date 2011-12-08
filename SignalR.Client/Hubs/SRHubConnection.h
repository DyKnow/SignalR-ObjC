//
//  SRHubConnection.h
//  SignalR
//
//  Created by Alex Billingsley on 10/31/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "SRConnection.h"

@class SRHubProxy;

@interface SRHubConnection : SRConnection

@property (nonatomic, readonly, strong) NSMutableDictionary *hubs;

+ (SRHubConnection *)connectionWithURL:(NSString *)URL;
- (id)initWithURL:(NSString *)url;
- (SRHubProxy *)createProxy:(NSString *)hubName;

- (void)start;
- (void)stop;

@end
