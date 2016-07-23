//
//  SRBlockOperation.h
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 7/23/16.
//  Copyright © 2016 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SRBlockOperation : NSBlockOperation @end
@interface SRTransportConnectTimeoutBlockOperation : SRBlockOperation @end
@interface SRServerSentEventsReconnectBlockOperation : SRBlockOperation @end