//
//  SRMockWaitBlockOperation.h
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 3/15/16.
//  Copyright © 2016 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SRMockWaitBlockOperation : NSObject

@property (readwrite, nonatomic, copy) void (^afterWait)();
@property (readwrite, nonatomic, assign) double waitTime;
@property (readwrite, nonatomic, strong) id mock;

- (instancetype)initWithWaitTime:(int)expectedWait;
- (void)stopMocking;

@end
