//
//  SRSseEvent.m
//  SignalR.Samples
//
//  Created by Alex Billingsley on 6/8/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import "SRSseEvent.h"

@interface SRSseEvent ()

@end

@implementation SRSseEvent

@synthesize type = _type;
@synthesize data = _data;

- (id)initWithType:(EventType)type data:(NSString *)data
{
    if (self = [super init])
    {
        _type = type;
        _data = data;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%d: %@",_type,_data];
}

+ (BOOL)tryParseEvent:(NSString *)line sseEvent:(SRSseEvent **)sseEvent
{
    *sseEvent = nil;
    
    if([line hasPrefix:@"data:"])
    {
        NSString *data = [[line substringFromIndex:@"data:".length] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        *sseEvent = [[SRSseEvent alloc] initWithType:Data data:data];
        return YES;
    }
    else if([line hasPrefix:@"id:"])
    {
        
        NSString *data = [line substringFromIndex:@"id:".length];
        *sseEvent = [[SRSseEvent alloc] initWithType:Id data:data];
        return YES;
    }
    
    return NO;
}

- (void)dealloc
{
    _data = nil;
}

@end
