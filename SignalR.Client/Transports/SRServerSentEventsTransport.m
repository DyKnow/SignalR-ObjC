//
//  SRServerSentEventsTransport.m
//  SignalR
//
//  Created by Alex Billingsley on 1/7/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import "SRServerSentEventsTransport.h"

#import "SRHttpHelper.h"
#import "SRHttpResponse.h"
#import "SRConnection.h"
#import "SRConnectionExtensions.h"

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

@end

#pragma mark -
#pragma mark AsyncStreamReader

#if NS_BLOCKS_AVAILABLE
typedef void (^onInitialized)(void);
typedef void (^onClose)(void);
#endif

@interface AsyncStreamReader : NSObject <NSStreamDelegate>

@property (strong, nonatomic, readonly)  NSOutputStream *stream;
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
- (void)stopReading;
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
        _stream.delegate = self;
        _buffer = [[ChunkBuffer alloc] init];
        _connection = connection;
        _transport = transport;
        _processedBytes = 0;
    }
    return self;
}

- (void)startReading
{
    _reading = YES;
}

- (void)stopReading
{
    _reading = NO;
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode 
{
    if(_reading)
    {
        NSMutableData *buffer = [NSMutableData dataWithData:[(NSOutputStream *)stream propertyForKey:NSStreamDataWrittenToMemoryStreamKey]];
        [buffer replaceBytesInRange:NSMakeRange(0, _processedBytes) withBytes:NULL length:0];
        
        int read = [buffer length];
                
        if(read > 0)
        {
            // Put chunks in the buffer
            [_buffer add:buffer length:read];
            _processedBytes = _processedBytes + [buffer length];
        }
        
        /*if (read == 0)
        {
            // Stop any reading we're doing
            [self stopReading];
            
            // Close the stream
            [stream close];
            
            //Call the close callback
            _closeCallback();
            return;
        }*/
        
        [self processBuffer];
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
                break;
            }
            case Data:
            {
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
                        [_transport onMessage:_connection response:sseEvent.data];
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

@end

#pragma mark -
#pragma mark ServerSentEventsTransport

@interface SRServerSentEventsTransport ()

@property (assign, nonatomic, readwrite) NSInteger reconnectDelay;

- (void)openConnection:(SRConnection *)connection data:(NSString *)data initializeCallback:(void (^)(void))initializeCallback errorCallback:(void (^)(SRErrorByReferenceBlock))errorCallback;

#define kTransportName @"serverSentEvents"
#define kReaderKey @"sse.reader"

@end

@implementation SRServerSentEventsTransport

@synthesize reconnectDelay = _reconnectDelay;

- (id)init
{
    if(self = [super initWithTransport:kTransportName])
    {
        _reconnectDelay = 2;
    }
    return self;
}

- (void)onStart:(SRConnection *)connection data:(NSString *)data initializeCallback:(void (^)(void))initializeCallback errorCallback:(void (^)(SRErrorByReferenceBlock))errorCallback
{
    [self openConnection:connection data:data initializeCallback:initializeCallback errorCallback:errorCallback];
}

//TODO: Check if exception is an IOException
- (void)openConnection:(SRConnection *)connection data:(NSString *)data initializeCallback:(void (^)(void))initializeCallback errorCallback:(void (^)(SRErrorByReferenceBlock))errorCallback
{
    if(connection.initialized) initializeCallback = nil;

    NSString *url = connection.url;
    
    if(connection.messageId == nil)
    {
        url = [url stringByAppendingString:kConnectEndPoint];
    }
    
    url = [url stringByAppendingFormat:@"%@",[self getReceiveQueryString:connection data:data]];

    [SRHttpHelper getAsync:url requestPreparer:^(NSMutableURLRequest * request)
    {
        [self prepareRequest:request forConnection:connection];

        [request addValue:@"text/event-stream" forHTTPHeaderField:@"Accept"];
    }
    continueWith:^(SRHttpResponse *httpResponse)
    {
#if DEBUG
         NSLog(@"openConnectionDidReceiveResponse: %@",httpResponse.response);
#endif
        BOOL isFaulted = ([httpResponse.response isKindOfClass:[NSError class]] || 
                          httpResponse.response == nil);
        
        if (isFaulted)
        {
            if ([httpResponse.response isKindOfClass:[NSError class]])
            {
                if(![self isRequestAborted:httpResponse.response]) //&& some interlocked code
                {
                    if (errorCallback)
                    {
                        SRErrorByReferenceBlock errorBlock = ^(NSError ** error)
                        {
                            *error = httpResponse.response;
                        };
                        errorCallback(errorBlock);
                    }
                    else
                    {
                        [connection didReceiveError:httpResponse.response];
                    }
                }
            }
        }
        else
        {
            //Get the response stream and read it for messages
            AsyncStreamReader *reader = [[AsyncStreamReader alloc] initWithStream:httpResponse.response connection:connection transport:self];
            reader.initializeCallback = ^()
            {
                if(initializeCallback != nil)
                {
                    initializeCallback();
                }
            };
            reader.closeCallback = ^()
            {
                NSMethodSignature *signature = [self methodSignatureForSelector:@selector(openConnection:data:initializeCallback:errorCallback:)];
                NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
                [invocation setSelector:@selector(openConnection:data:initializeCallback:errorCallback:)];
                [invocation setTarget:self ];
                
                NSArray *args = [[NSArray alloc] initWithObjects:connection,data,nil,nil, nil];
                for(int i =0; i<[args count]; i++)
                {
                    int arguementIndex = 2 + i;
                    NSString *argument = [args objectAtIndex:i];
                    [invocation setArgument:&argument atIndex:arguementIndex];
                }
                [NSTimer scheduledTimerWithTimeInterval:_reconnectDelay invocation:invocation repeats:NO];
            };
            [reader startReading];
            
            //Set the reader for this connection
            [connection.items setObject:reader forKey:kReaderKey];
        }
    }];
}

- (void)onBeforeAbort:(SRConnection *)connection
{
    //Get the reader from the connection and stop it
    id reader = nil;
    if((reader = [connection getValue:kReaderKey]))
    {
        //Stop reading data from the stream
        [reader stopReading];
        
        //Remove the reader
        [connection.items removeObjectForKey:kReaderKey];
    }
}

@end