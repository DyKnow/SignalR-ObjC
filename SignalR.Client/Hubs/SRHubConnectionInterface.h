//
//  SRHubConnectionInterface.h
//  SignalR.Client.ObjC
//
//  Created by Bryce Kahle on 3/1/13.
//  Copyright (c) 2013 DyKnow LLC. All rights reserved.
//

#import "SRConnectionInterface.h"
#import "SRHubResult.h"

typedef void (^SRHubResultBlock)(SRHubResult *result);

@protocol SRHubConnectionInterface <NSObject, SRConnectionInterface>

- (NSString *)registerCallback:(SRHubResultBlock)callback;

@end
