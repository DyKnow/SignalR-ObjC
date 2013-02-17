//
//  SRConnectionExtensions.m
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 2/17/13.
//  Copyright (c) 2013 DyKnow LLC. All rights reserved.
//

#import "SRConnectionExtensions.h"

@implementation SRConnection (Extensions)

+ (BOOL)ensureReconnecting:(id <SRConnectionInterface>)connection {
    if ([connection changeState:connected toState:reconnecting]) {
        [connection willReconnect];
    }
    return (connection.state == reconnecting);
}

@end
