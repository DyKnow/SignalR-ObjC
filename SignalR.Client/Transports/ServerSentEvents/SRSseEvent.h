//
//  SRSseEvent.h
//  SignalR.Samples
//
//  Created by Alex Billingsley on 6/8/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SREventType.h"

@interface SRSseEvent : NSObject

@property (assign, nonatomic, readwrite) EventType type;
@property (strong, nonatomic, readwrite) NSString *data;

- (id)initWithType:(EventType)type data:(NSString *)data;

+ (BOOL)tryParseEvent:(NSString *)line sseEvent:(SRSseEvent **)sseEvent;

@end
