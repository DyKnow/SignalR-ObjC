//
//  SRServerSentEventsTransport.m
//  SignalR
//
//  Created by Alex Billingsley on 1/7/12.
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

#import "SRServerSentEventsTransport.h"
#import "SRSignalRConfig.h"

#import "AFNetworking.h"
#import "SRDefaultHttpClient.h"
#import "SRConnection.h"
#import "SRConnectionExtensions.h"
#import "NSTimer+Blocks.h"

#pragma mark - 
#pragma mark SseEvent

typedef enum {
    Id,
    Data
} EventType;

@interface SseEvent : NSObject 

@property (assign, nonatomic, readwrite) EventType type;
@property (strong, nonatomic, readwrite) NSString *data;

@end

@implementation SseEvent

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

- (void)dealloc
{
    _data = nil;
}

@end

#pragma mark -
#pragma mark ChunkBuffer

@interface ChunkBuffer : NSObject 

@property (assign, nonatomic, readwrite) int offset;
@property (strong, nonatomic, readwrite) NSMutableString *buffer;
@property (strong, nonatomic, readwrite) NSMutableString *lineBuilder;

- (BOOL)hasChunks;
- (NSString *)readLine;
- (void)add:(id)buffer length:(int)length;

@end

@implementation ChunkBuffer

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

- (void)add:(NSData *)buffer length:(int)length
{
    [_buffer appendString:[[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding]];
}

- (void)dealloc
{
    _offset = 0;
    _buffer = nil;
    _lineBuilder = nil;
}

@end

#pragma mark -
#pragma mark AsyncStreamReader

#if NS_BLOCKS_AVAILABLE
typedef void (^onInitialized)(void);
typedef void (^onClose)(void);
#endif

@interface AsyncStreamReader : NSObject <NSStreamDelegate>

@property (strong, nonatomic, readwrite)  NSOutputStream *stream;
@property (strong, nonatomic, readonly)  ChunkBuffer *buffer;
@property (copy) onInitialized initializeCallback;
@property (copy) onClose closeCallback;
@property (strong, nonatomic, readonly)  SRConnection *connection;
@property (assign, nonatomic, readonly)  int processingQueue;
@property (assign, nonatomic, readonly)  BOOL reading;
@property (assign, nonatomic, readonly)  BOOL processingBuffer;

@property (strong, nonatomic, readonly)  SRServerSentEventsTransport *transport;
@property (assign, nonatomic, readwrite) int processedBytes;

- (id)initWithStream:(id)steam connection:(SRConnection *)connection transport:(SRServerSentEventsTransport *)transport;

- (void)startReading;
- (void)stopReading:(BOOL)raiseCloseCallback;
- (void)processBuffer;
- (void)processChunks;
- (BOOL)tryParseEvent:(NSString *)line sseEvent:(SseEvent **)sseEvent;

@end

@implementation AsyncStreamReader

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
        _buffer = [[ChunkBuffer alloc] init];
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
            if (![_transport isRequestAborted:[stream streamError]])
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
        
        SseEvent *sseEvent = nil;
        if(![self tryParseEvent:line sseEvent:&sseEvent])
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

- (BOOL)tryParseEvent:(NSString *)line sseEvent:(SseEvent **)sseEvent
{
    *sseEvent = nil;
    
    if([line hasPrefix:@"data:"])
    {
        NSString *data = [[line substringFromIndex:@"data:".length] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        *sseEvent = [[SseEvent alloc] initWithType:Data data:data];
        return YES;
    }
    else if([line hasPrefix:@"id:"])
    {
        
        NSString *data = [line substringFromIndex:@"id:".length];
        *sseEvent = [[SseEvent alloc] initWithType:Id data:data];
        return YES;
    }
    
    return NO;
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

#pragma mark -
#pragma mark ServerSentEventsTransport

@interface SRServerSentEventsTransport ()

@property (assign, nonatomic, readwrite) NSInteger reconnectDelay;
@property (assign, nonatomic, readwrite) NSInteger initializedCalled;

- (void)openConnection:(SRConnection *)connection data:(NSString *)data initializeCallback:(void (^)(void))initializeCallback errorCallback:(void (^)(SRErrorByReferenceBlock))errorCallback;

#define kTransportName @"serverSentEvents"
#define kReaderKey @"sse.reader"

@end

@implementation SRServerSentEventsTransport

@synthesize connectionTimeout = _connectionTimeout;
@synthesize reconnectDelay = _reconnectDelay;
@synthesize initializedCalled = _initializedCalled;

- (id)init
{
    if(self = [self initWithHttpClient:[[SRDefaultHttpClient alloc] init]])
    {
    }
    return self;
}

- (id)initWithHttpClient:(id<SRHttpClient>)httpClient
{
    if (self = [super initWithHttpClient:httpClient transport:kTransportName])
    {
        _connectionTimeout = 2;
        _reconnectDelay = 2;
    }
    return self;
}


- (void)onStart:(SRConnection *)connection data:(NSString *)data initializeCallback:(void (^)(void))initializeCallback errorCallback:(void (^)(SRErrorByReferenceBlock))errorCallback
{
    [self openConnection:connection data:data initializeCallback:initializeCallback errorCallback:errorCallback];
}

- (void)reconnect:(SRConnection *)connection data:(NSString *)data
{
    if(!connection.isActive)
    {
        return;
    }
    
    //Wait for a bit before reconnecting
    [NSTimer scheduledTimerWithTimeInterval:_reconnectDelay block:^
    {
        //Now attempt a reconnect
        [self openConnection:connection data:data initializeCallback:nil errorCallback:nil];
    } repeats:NO];
}

- (void)openConnection:(SRConnection *)connection data:(NSString *)data initializeCallback:(void (^)(void))initializeCallback errorCallback:(void (^)(SRErrorByReferenceBlock))errorCallback
{
    // If we're reconnecting add /connect to the url
    BOOL reconnecting = initializeCallback == nil;
    
    NSString *url = [(reconnecting ? connection.url : [connection.url stringByAppendingString:kConnectEndPoint]) stringByAppendingFormat:@"%@",[self getReceiveQueryString:connection data:data]];

    [self.httpClient getAsync:url requestPreparer:^(id request)
    {
        [self prepareRequest:request forConnection:connection];

        if([request isKindOfClass:[NSMutableURLRequest class]])
        {
            [request addValue:@"text/event-stream" forHTTPHeaderField:@"Accept"];
        }
    }
    continueWith:^(id response)
    {
        BOOL isFaulted = ([response isKindOfClass:[NSError class]] || 
                          response == nil);
        
        if (isFaulted)
        {
            if ([response isKindOfClass:[NSError class]])
            {
                if(![self isRequestAborted:response])
                {                        
                    if (errorCallback != nil && 
                        _initializedCalled == 0)
                    {
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_HTTP_BASED_TRANSPORT
                        SR_DEBUG_LOG(@"[SERVER_SENT_EVENTS] isFaulted will report to errorCallback");
#endif
                        _initializedCalled = 1;
                        
                        SRErrorByReferenceBlock errorBlock = ^(NSError ** error)
                        {
                            *error = response;
                        };
                        errorCallback(errorBlock);
                    }
                    else if(reconnecting)
                    {
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_HTTP_BASED_TRANSPORT
                        SR_DEBUG_LOG(@"[SERVER_SENT_EVENTS] isFaulted will report to connection");
#endif
                        // Only raise the error event if we failed to reconnect
                        [connection didReceiveError:response];
                    }
                }
                
                if(reconnecting)
                {
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_HTTP_BASED_TRANSPORT
                    SR_DEBUG_LOG(@"[SERVER_SENT_EVENTS] reconnecting");
#endif
                    //Retry
                    [self reconnect:connection data:data];
                }
            }
            else if(response == nil)
            {
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_HTTP_BASED_TRANSPORT
                SR_DEBUG_LOG(@"[SERVER_SENT_EVENTS] buffer is 0 reading will stop and resume after reconnecting");
#endif
                AsyncStreamReader *reader = nil;
                if((reader = [connection getValue:kReaderKey]))
                {
                    [reader stopReading:YES];
                    return;
                }  
            }
        }
        else
        {
            //Get the response stream and read it for messages
            AsyncStreamReader *reader = [[AsyncStreamReader alloc] initWithStream:response connection:connection transport:self];
            reader.initializeCallback = ^()
            {
                if(initializeCallback != nil && _initializedCalled == 0)
                {
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_HTTP_BASED_TRANSPORT
                    SR_DEBUG_LOG(@"[SERVER_SENT_EVENTS] connection is initialized");
#endif
                    _initializedCalled = 1;
                    
                    initializeCallback();
                }
            };
            reader.closeCallback = ^()
            {
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_HTTP_BASED_TRANSPORT
                SR_DEBUG_LOG(@"[SERVER_SENT_EVENTS] stream did close, will reopen in %d seconds...",_reconnectDelay);
#endif
                [self reconnect:connection data:data];
            };
            
            if(reconnecting)
            {
                // Raise the reconnect event if the connection comes back up
                [connection didReconnect];
            }
            
            [reader startReading];
            
            //Set the reader for this connection
            [connection.items setObject:reader forKey:kReaderKey];
        }
    }];
    
    if (initializeCallback != nil)
    {
        [NSTimer scheduledTimerWithTimeInterval:_connectionTimeout block:
        ^{
            if(_initializedCalled == 0)
            {
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_HTTP_BASED_TRANSPORT
                SR_DEBUG_LOG(@"[SERVER_SENT_EVENTS] connection did timeout");
#endif
                _initializedCalled = 1;
                
                // Stop the connection
                [self stop:connection];
                
                // Connection timeout occured
                if (errorCallback != nil)
                {
                    SRErrorByReferenceBlock errorBlock = ^(NSError ** error)
                    {
                        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
                        [userInfo setObject:[NSString stringWithFormat:@"TimeoutException"] forKey:NSLocalizedFailureReasonErrorKey];
                        [userInfo setObject:[NSString stringWithFormat:@"Transport took longer than %d to connect",_connectionTimeout] forKey:NSLocalizedDescriptionKey];
                        *error = [NSError errorWithDomain:[NSString stringWithFormat:@"com.SignalR-ObjC.%@",NSStringFromClass([self class])] 
                                                             code:NSURLErrorTimedOut 
                                                         userInfo:userInfo];
                    };
                    errorCallback(errorBlock);
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_HTTP_BASED_TRANSPORT
                    SR_DEBUG_LOG(@"[SERVER_SENT_EVENTS] did call errorCallBack with timeout error");
#endif
                }
            }
        } repeats:NO];
    }
}

- (void)onBeforeAbort:(SRConnection *)connection
{
#if DEBUG_SERVER_SENT_EVENTS || DEBUG_HTTP_BASED_TRANSPORT
    SR_DEBUG_LOG(@"[SERVER_SENT_EVENTS] will abort connection");
#endif
    //Get the reader from the connection and stop it
    id reader = nil;
    if((reader = [connection getValue:kReaderKey]))
    {
        //Stop reading data from the stream
        [reader stopReading:NO];
        
        //Remove the reader
        [connection.items removeObjectForKey:kReaderKey];
    }
}

- (void)dealloc
{
    _connectionTimeout = 0;
    _reconnectDelay = 0;
    _initializedCalled = 0;
}

@end