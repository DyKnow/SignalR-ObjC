//
//  SRConnectionExtensions.h
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 2/17/13.
//  Copyright (c) 2013 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRConnection.h"

@interface SRConnection (Extensions)

+ (BOOL)ensureReconnecting:(id <SRConnectionInterface>)connection;

@end
