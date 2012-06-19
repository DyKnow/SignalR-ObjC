//
//  SREventSourceStreamReader.m
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

#import "SREventSourceStreamReader.h"
#import "SRChunkBuffer.h"
#import "SRConnection.h"
#import "SRExceptionHelper.h"
#import "SRServerSentEventsTransport.h"
#import "SRSignalRConfig.h"
#import "SRSseEvent.h"

@interface SREventSourceStreamReader ()

@property (strong, nonatomic, readwrite)  NSOutputStream *stream;
@property (strong, nonatomic, readonly)  SRChunkBuffer *buffer;
@property (assign, nonatomic, readonly)  BOOL reading;
@property (assign, nonatomic, readwrite) int processedBytes;
@property (assign, nonatomic, readonly)  BOOL processingBuffer;
@property (assign, nonatomic, readonly)  int processingQueue;

- (BOOL)processing;

- (void)processBuffer;

- (void)onError:(NSError *)error;
- (void)onOpened;
- (void)onMessage:(SRSseEvent *)sseEvent;
- (void)onClosed;

@end

@implementation SREventSourceStreamReader

@synthesize opened = _opened;
@synthesize closed = _closed;
@synthesize message = _message;
@synthesize error = _error;

@synthesize stream = _stream;
@synthesize buffer = _buffer;
@synthesize reading = _reading;
@synthesize processedBytes = _processedBytes;
@synthesize processingBuffer = _processingBuffer;
@synthesize processingQueue = _processingQueue;

- (id)initWithStream:(NSOutputStream *)steam
{
    if (self = [super init])
    {
        _stream = steam;
        _buffer = [[SRChunkBuffer alloc] init];
        _reading = NO;

        _processedBytes = 0;
    }
    return self;
}

- (void)start
{
    _stream.delegate = self;
}

- (BOOL)processing
{
    return _reading;
}

- (void)close
{
    if (_reading)
    {
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_HTTP_BASED_TRANSPORT
        SR_DEBUG_LOG(@"[EventSourceReader] Connection Closed");
#endif
        _stream.delegate = nil;
        [_stream close];
        _reading = NO;

        [self onClosed];       
    }
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode 
{
    switch (eventCode)
    {
        case NSStreamEventOpenCompleted:
        {
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_HTTP_BASED_TRANSPORT
            SR_DEBUG_LOG(@"[EventSourceReader] Connection Opened");
#endif
            _reading = YES;
            [self onOpened];
            break;
        }
        case NSStreamEventHasSpaceAvailable:
        {
            if (![self processing])
            {
                return;
            }
            
            NSMutableData *buffer = [NSMutableData dataWithData:[(NSOutputStream *)stream propertyForKey:NSStreamDataWrittenToMemoryStreamKey]];
            [buffer replaceBytesInRange:NSMakeRange(0, _processedBytes) withBytes:NULL length:0];
            
            int read = [buffer length];
            
            if(read > 0)
            {
                // Put chunks in the buffer
                [_buffer add:buffer length:read];
                _processedBytes = _processedBytes + [buffer length];
            }
            
            [self processBuffer];
            
            break;
        }
        case NSStreamEventErrorOccurred:
        {
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_HTTP_BASED_TRANSPORT
            SR_DEBUG_LOG(@"[SERVER_SENT_EVENTS] an error %@ occured while reading the stream",[stream streamError]);
#endif
            if (![SRExceptionHelper isRequestAborted:[stream streamError]])
            {
                //if(![[stream streamError] isKindOfClass:IOException]
                    [self onError:[stream streamError]];
            }
            else
            {
                [self onClosed];
            }
            break;
        }
        case NSStreamEventEndEncountered:
        case NSStreamEventNone:
        case NSStreamEventHasBytesAvailable:
        default:
            break;
    }
}

- (void)processBuffer
{
    if (![self processing])
    {
        return;
    }
    
    if (_processingBuffer)
    {
        // Increment the number of times we should process messages
        _processingQueue++;
        return;
    }
    
    _processingBuffer = true;
    
    int total = MAX(1, _processingQueue);
    
    for (int i = 0; i < total; i++)
    {
        while ([_buffer hasChunks])
        {
            NSString *line = [_buffer readLine];
            
            // No new lines in the buffer so stop processing
            if (line == nil)
            {
                break;
            }
            
            SRSseEvent *sseEvent = nil;
            if(![SRSseEvent tryParseEvent:line sseEvent:&sseEvent])
            {
                continue;
            }
            
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_HTTP_BASED_TRANSPORT
            SR_DEBUG_LOG(@"[EventSourceReader] SSE READ: %@",sseEvent);
#endif
            [self onMessage:sseEvent];
        }
    }
    
    if (_processingQueue > 0)
    {
        _processingQueue -= total;
    }
    
    _processingBuffer = false;
}

#pragma mark -
#pragma mark Dispatch Blocks

- (void)onError:(NSError *)error
{
    if(self.error)
    {
        self.error(error);
    }
}

- (void)onOpened
{
    if(self.opened)
    {
        self.opened();
    }
}

- (void)onMessage:(SRSseEvent *)sseEvent
{
    if(self.message)
    {
        self.message(sseEvent);
    }
}

- (void)onClosed;
{
    if(self.closed)
    {
        self.closed();
    }
}

- (void)dealloc
{
    _stream = nil;
    _buffer = nil;
    _reading = NO;
}

@end
