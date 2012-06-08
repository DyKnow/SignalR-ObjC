//
//  SREventSourceStreamReader.m
//  SignalR.Samples
//
//  Created by Alex Billingsley on 6/8/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import "SREventSourceStreamReader.h"
#import "SRChunkBuffer.h"
#import "SRConnection.h"
#import "SRSseEvent.h"
#import "SRServerSentEventsTransport.h"
#import "SRExceptionHelper.h"

@interface SREventSourceStreamReader ()

@end
@implementation SREventSourceStreamReader

@synthesize stream = _stream;
@synthesize buffer = _buffer;
@synthesize initializeCallback = _initializeCallback;
@synthesize closeCallback = _closeCallback;
@synthesize connection = _connection;
@synthesize processingQueue = _processingQueue;
@synthesize reading = _reading;
@synthesize processingBuffer = _processingBuffer;

@synthesize transport = _transport;
@synthesize processedBytes = _processedBytes;

- (id)initWithStream:(NSOutputStream *)steam connection:(SRConnection *)connection transport:(SRServerSentEventsTransport *)transport
{
    if (self = [super init])
    {
        _stream = steam;
        _buffer = [[SRChunkBuffer alloc] init];
        _connection = connection;
        _transport = transport;
        _processedBytes = 0;
    }
    return self;
}

- (void)startReading
{
    _stream.delegate = self;
}

- (void)stopReading:(BOOL)raiseCloseCallback
{
    _reading = NO;
    if(raiseCloseCallback)
    {
        if(_closeCallback)
        {
            _closeCallback();
        }
    }
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode 
{
    switch (eventCode)
    {
        case NSStreamEventOpenCompleted:
        {
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_HTTP_BASED_TRANSPORT
            SR_DEBUG_LOG(@"[SERVER_SENT_EVENTS] did start reading");
#endif
            _reading = YES;
            break;
        }
        case NSStreamEventHasSpaceAvailable:
        {
            if (!_reading)
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
                [_connection didReceiveError:[stream streamError]];
            }
            
            [self stopReading:YES];
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
    if (!_reading)
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
        if (!_reading)
        {
            return;
        }
        
        [self processChunks];
    }
    
    if (_processingQueue > 0)
    {
        _processingQueue -= total;
    }
    
    _processingBuffer = false;
}

- (void)processChunks
{
    while (_reading && [_buffer hasChunks])
    {
        NSString *line = [_buffer readLine];
        
        // No new lines in the buffer so stop processing
        if (line == nil)
        {
            break;
        }
        
        if (!_reading)
        {
            return;
        }
        
        SRSseEvent *sseEvent = nil;
        if(![SRSseEvent tryParseEvent:line sseEvent:&sseEvent])
        {
            continue;
        }
        
        if(!_reading)
        {
            return;
        }
        
        switch (sseEvent.type) {
            case Id:
            {
                _connection.messageId = [NSNumber numberWithInteger:[sseEvent.data integerValue]];
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_HTTP_BASED_TRANSPORT
                SR_DEBUG_LOG(@"[SERVER_SENT_EVENTS] did read 'id:'= %@",sseEvent.data);
#endif
                break;
            }
            case Data:
            {
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_HTTP_BASED_TRANSPORT
                SR_DEBUG_LOG(@"[SERVER_SENT_EVENTS] did read 'data:'= %@",sseEvent.data);
#endif
                if([sseEvent.data isEqualToString:@"initialized"])
                {
                    if (_initializeCallback != nil)
                    {
                        // Mark the connection as started
                        _initializeCallback();
                    }
                }
                else
                {
                    if(_reading)
                    {
                        //We don't care about timeout message here since it will just reconnect
                        //as part of being a long running request
                        
                        BOOL timedOutReceived = NO;
                        BOOL disconnectReceived = NO;
                        
                        [_transport processResponse:_connection response:sseEvent.data timedOut:&timedOutReceived disconnected:&disconnectReceived];
                        
                        if(disconnectReceived)
                        {
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_HTTP_BASED_TRANSPORT
                            SR_DEBUG_LOG(@"[SERVER_SENT_EVENTS] disconnectReceived should disconnect");
#endif
                            [_connection stop];
                        }
                        
                        if(timedOutReceived)
                        {
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_HTTP_BASED_TRANSPORT
                            SR_DEBUG_LOG(@"[SERVER_SENT_EVENTS] timeoutReceived should reconnect");
#endif
                            return;
                        }
                    }
                }
                break;
            }
            default:
                break;
        }
    }
}

- (void)dealloc
{
    _stream = nil;
    _buffer = nil;
    _initializeCallback = nil;
    _closeCallback = nil;
    _connection = nil;
    _processingQueue = 0;
    _reading = NO;
    _processingBuffer = NO;
    _transport = nil;
    _processedBytes = 0;
}

@end
