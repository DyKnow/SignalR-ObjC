//
//  NSTimer+Blocks.m
//  SignalR.Samples
//
//  Created by Alex Billingsley on 1/29/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import "NSTimer+Blocks.h"

@implementation NSTimer (Blocks)

+ (id)scheduledTimerWithTimeInterval:(NSTimeInterval)inTimeInterval block:(void (^)())inBlock repeats:(BOOL)inRepeats
{
    void (^block)() = [inBlock copy];
    id timer = [self scheduledTimerWithTimeInterval:inTimeInterval target:self selector:@selector(executeBlock:) userInfo:block repeats:inRepeats];

    return timer;
}

+ (id)timerWithTimeInterval:(NSTimeInterval)inTimeInterval block:(void (^)())inBlock repeats:(BOOL)inRepeats
{
    void (^block)() = [inBlock copy];
    id timer = [self timerWithTimeInterval:inTimeInterval target:self selector:@selector(executeBlock:) userInfo:block repeats:inRepeats];

    return timer;
}

+(void)executeBlock:(NSTimer *)inTimer;
{
    if([inTimer userInfo])
    {
        void (^block)() = (void (^)())[inTimer userInfo];
        block();
    }
}

@end
