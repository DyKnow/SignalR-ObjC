//
//  SRTransportRequestSerialization.h
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 7/26/16.
//  Copyright © 2016 DyKnow LLC. All rights reserved.
//

#import <AFNetworking/AFURLRequestSerialization.h>
#import "SRConnectionInterface.h"

@interface SRTransportRequestSerializer : AFHTTPRequestSerializer

@property (nonatomic, assign) id <SRConnectionInterface> connection;

+ (instancetype)serializerWithConnection:(id <SRConnectionInterface>)connection;

@end

@interface SRLongPollingRequestSerializer : SRTransportRequestSerializer

@end

@interface SREventSourceRequestSerializer : SRTransportRequestSerializer

@end

@interface SRWebsocketRequestSerializer : SRTransportRequestSerializer

@end