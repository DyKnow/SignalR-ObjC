//
//  SRServerSentEventsTransport.m
//  SignalR
//
//  Created by Alex Billingsley on 1/7/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import "SRServerSentEventsTransport.h"

#import "SRConnection.h"
#import "SRConnectionExtensions.h"

#import "SRHttpHelper.h"
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

- (id)initWithStream:(id)steam connection:(SRConnection *)connection initializeCallback:(id)initializeCallback errorCallback:(id)errorCallback;

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

- (id)initWithStream:(id)steam connection:(SRConnection *)connection initializeCallback:(id)initializeCallback errorCallback:(id)errorCallback
{
    if (self = [super init])
    {
        _stream = steam;
        _connection = connection;
        _initializedCallback = initializeCallback;
        _errorCallback = _errorCallback;
    }
    return self;
}
- (void)startReading
{
    _reading = YES;
    [self readLoop];
}

- (void)stopReading
{
    _reading = NO;
}

//TODO: implement readloop
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
        
        if(line == nil)
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
            {
                NSLog(@"%@",sseEvent.data);
                break;
            }
            case Data:
            {
                if([sseEvent.data isEqualToString:@"initialized"])
                {
                    NSLog(@"Initialize the callback");
                    //initializeCallback();
                }
                else
                {
                    NSLog(@"onMessage%@",sseEvent.data);
                    //onMessage(_connection,sseEvent.data);
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
        NSString *data = [line substringFromIndex:@"data:".length];
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

//TODO: handle callbacks
- (void)openConnection:(SRConnection *)connection data:(NSString *)data initializeCallback:(id)initializeCallback errorCallback:(id)errorCallback
{
    NSString *url = connection.url;

    url = [url stringByAppendingFormat:@"%@",[self getReceiveQueryString:connection data:data]];
    
#if DEBUG
    NSLog(@"%@",url);
#endif
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
    
    [SRHttpHelper postAsync:url requestPreparer:prepareRequest continueWith:
     ^(id response) {
#if DEBUG
         NSLog(@"openConnectionDidReceiveResponse: %@",response);
#endif
         BOOL isFaulted = ([response isKindOfClass:[NSError class]] || 
                           [response isEqualToString:@""] || response == nil ||
                           [response isEqualToString:@"null"]);
         if(isFaulted)
         {
             //errorCallback(task.excpetion);
         }
         else
         {
             AsyncStreamReader *reader = [[AsyncStreamReader alloc] initWithStream:response connection:connection initializeCallback:initializeCallback errorCallback:errorCallback];
             [reader startReading];
             
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