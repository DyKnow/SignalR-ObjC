//
//  SRServerSentEventsTransport.m
//  SignalR
//
//  Created by Alex Billingsley on 1/7/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import "SRServerSentEventsTransport.h"

#import "SRConnection.h"

#import "HttpHelper.h"
#import "NSString+Url.h"

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
        _data = _data;
    }
    return self;
}

@end

#pragma mark - 
#pragma mark ChunkBuffer

@interface ChunkBuffer : NSObject 

@property (assign, nonatomic, readonly) NSInteger offset;
@property (strong, nonatomic, readonly) NSString *buffer;
@property (strong, nonatomic, readonly) NSString *lineBuilder;

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
        _buffer = [NSString stringWithFormat:@""];
        _lineBuilder = [NSString stringWithFormat:@""];
    }
    return self;
}

- (BOOL)hasChunks
{
    return (_offset < _buffer.length);
}

- (NSString *)readLine
{
    for (int i=_offset; i<_buffer.length; i++, _offset++)
    {

    }
    
    return nil;
}

- (void)add:(id)buffer length:(int)length
{
    
}

@end

#pragma mark -
#pragma mark AsyncStreamReader

@interface AsyncStreamReader : NSObject

@property (strong, nonatomic, readonly)  id stream;
@property (strong, nonatomic, readonly)  ChunkBuffer *buffer;
@property (strong, nonatomic, readonly)  id initializedCallback;
@property (strong, nonatomic, readonly)  id errorCallback;
@property (strong, nonatomic, readonly)  SRConnection *connection;
@property (assign, nonatomic, readonly)  NSInteger processingQueue;
@property (assign, nonatomic, readonly)  BOOL reading;
@property (assign, nonatomic, readonly)  BOOL processingBuffer;

- (void)startReading;
- (void)stopReading;
- (void)readLoop;
- (void)processBuffer;
- (void)processChunks;
- (BOOL)tryParseEvent:(NSString *)line sseEvent:(SseEvent **)sseEvent;

@end

@implementation AsyncStreamReader

@synthesize stream = _stream;
@synthesize buffer = _buffer;
@synthesize initializedCallback = _initializedCallback;
@synthesize errorCallback = _errorCallback;
@synthesize connection = _connection;
@synthesize processingQueue = _processingQueue;
@synthesize reading = _reading;
@synthesize processingBuffer = _processingBuffer;

- (void)startReading
{
    _reading = YES;
    [self readLoop];
}

- (void)stopReading
{
    _reading = NO;
}

- (void)readLoop
{
    if(!_reading)
    {
        return;
    }
}

- (void)processBuffer
{
    if(!_reading)
    {
        return;
    }
    
    if(_processingBuffer)
    {
        //Increment the number of times we should process messages
        _processingQueue = _processingQueue + 1;
        return;
    }
    
    _processingBuffer = YES;
    
    int total = _processingQueue; //Math.max(1,_processingQueue);
    
    for (int i=0; i<total; i++)
    {
        if (!_reading)
        {
            return;
        }
        
        [self processChunks];
    }
    
    if(_processingQueue > 0)
    {
        _processingQueue = _processingQueue - 1;
    }
    
    _processingBuffer = NO;
}

- (void)processChunks
{
    while (_reading && [_buffer hasChunks]) 
    {
        NSString *line = [_buffer readLine];
        
        if(!line || [line isEqualToString:@""] == YES)
        {
            break;
        }
        
        if(!_reading)
        {
            break;
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
                
                break;
            case Data:
                
                break;
            default:
                break;
        }
    }
}

- (BOOL)tryParseEvent:(NSString *)line sseEvent:(SseEvent **)sseEvent
{
    sseEvent = nil;
    
    return NO;
}
@end



#pragma mark -
#pragma mark ServerSentEventsTransport

void (^prepareRequest)(NSMutableURLRequest *);

@interface SRServerSentEventsTransport ()

- (void)openConnection:(SRConnection *)connection data:(NSString *)data initializeCallback:(id)initializeCallback errorCallback:(id)errorCallback;

#define kTransportName @"serverSentEvents"
#define kReaderKey @"sse.reader"

@end

@implementation SRServerSentEventsTransport

- (id)init
{
    if(self = [super initWithTransport:kTransportName])
    {
        
    }
    return self;
}

- (void)onStart:(SRConnection *)connection data:(NSString *)data initializeCallback:(id)initializeCallback errorCallback:(id)errorCallback
{
    [self openConnection:connection data:data initializeCallback:initializeCallback errorCallback:errorCallback];
}

- (void)openConnection:(SRConnection *)connection data:(NSString *)data initializeCallback:(id)initializeCallback errorCallback:(id)errorCallback
{
    NSString *url = connection.url;

    url = [url stringByAppendingFormat:@"%@",[self getReceiveQueryString:connection data:data]];
    
    prepareRequest = ^(NSMutableURLRequest * request){
        [connection.items setObject:request forKey:kHttpRequestKey];
#if TARGET_IPHONE || TARGET_IPHONE_SIMULATOR
        [request setValue:[connection createUserAgentString:@"SignalR.Client.iOS"] forHTTPHeaderField:@"User-Agent"];
#elif TARGET_OS_MAC
        [request setValue:[connection createUserAgentString:@"SignalR.Client.MAC"] forHTTPHeaderField:@"User-Agent"];
#endif
        
        [request setValue:@"text/event-stream" forHTTPHeaderField:@"Accept"];
        
        if(connection.messageId != nil)
        {
            [request setValue:[connection.messageId stringValue] forHTTPHeaderField:@"Last-Event-ID"];
        }
    };
    
    [[HttpHelper sharedHttpRequestManager] postAsync:connection url:url requestPreparer:prepareRequest onCompletion:
     ^(SRConnection *connection, id response) 
    {
         BOOL isFaulted = ([response isKindOfClass:[NSError class]] || 
                           [response isEqualToString:@""] || response == nil ||
                           [response isEqualToString:@"null"]);
        if(isFaulted)
        {
            //errorCallback(task.excpetion);
        }
        else
        {
            
        }
     }];
}

- (void)onBeforeAbort:(SRConnection *)connection
{
    
}

@end