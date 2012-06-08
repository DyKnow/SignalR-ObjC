//
//  SRChunkBuffer.m
//  SignalR.Samples
//
//  Created by Alex Billingsley on 6/8/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import "SRChunkBuffer.h"

@interface SRChunkBuffer ()

@end

@implementation SRChunkBuffer

@synthesize offset = _offset;
@synthesize buffer = _buffer;
@synthesize lineBuilder = _lineBuilder;

- (id)init
{
    if (self = [super init])
    {
        _buffer = [NSMutableString string];
        _lineBuilder = [NSMutableString string];
    }
    return self;
}

- (BOOL)hasChunks
{
    return (_offset < [_buffer length]);
}

- (void)add:(NSData *)buffer length:(int)length
{
    [_buffer appendString:[[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding]];
}

- (NSString *)readLine
{
    for (int i = _offset; i < [_buffer length]; i++, _offset++)
    {
        if ([_buffer characterAtIndex:i] == '\n')
        {
            NSRange range;
            range.location = 0;
            range.length = _offset + 1;
            [_buffer deleteCharactersInRange:range];
            NSString *line = [NSString stringWithString:_lineBuilder];
            
            [_lineBuilder setString:@""];
            _offset = 0;
            
            return line;
        }
        [_lineBuilder appendFormat:[NSString stringWithFormat:@"%C",[_buffer characterAtIndex:i]]];        
    }
    
    return nil;
}

- (void)dealloc
{
    _offset = 0;
    _buffer = nil;
    _lineBuilder = nil;
}

@end
