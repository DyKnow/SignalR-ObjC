//
//  SRChunkBuffer.m
//  SignalR
//
//  Created by Alex Billingsley on 6/8/12.
//  Copyright (c) 2011 DyKnow LLC. (http://dyknow.com/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
//  documentation files (the "Software"), to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and 
//  to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of 
//  the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
//  THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
//  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
//  DEALINGS IN THE SOFTWARE.
//

#import "SRChunkBuffer.h"

@interface SRChunkBuffer ()

@property (assign, nonatomic, readwrite) int offset;
@property (strong, nonatomic, readwrite) NSMutableString *buffer;
@property (strong, nonatomic, readwrite) NSMutableString *lineBuilder;

@end

@implementation SRChunkBuffer

- (instancetype)init {
    if (self = [super init]) {
        _buffer = [NSMutableString string];
        _lineBuilder = [NSMutableString string];
    }
    return self;
}

- (BOOL)hasChunks {
    return (_offset < [_buffer length]);
}

- (void)add:(NSData *)buffer {
    [_buffer appendString:[[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding]];
}

- (NSString *)readLine {
    for (int i = _offset; i < [_buffer length]; i++, _offset++) {
        if ([_buffer characterAtIndex:i] == '\n') {
            [_buffer deleteCharactersInRange:NSMakeRange(0, _offset + 1)];
            NSString *line = [NSString stringWithString:_lineBuilder];
            
            [_lineBuilder setString:@""];
            _offset = 0;
            
            return line;
        }
        [_lineBuilder appendFormat:@"%C",[_buffer characterAtIndex:i]];        
    }
    
    return nil;
}

@end
