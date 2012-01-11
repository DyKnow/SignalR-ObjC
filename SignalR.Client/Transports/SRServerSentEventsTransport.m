//
//  SRServerSentEventsTransport.m
//  SignalR
//
//  Created by Alex Billingsley on 1/7/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import "SRServerSentEventsTransport.h"

#import "SRHttpHelper.h"
#import "ASIHTTPRequest.h"
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
#pragma mark AsyncStreamReader

#if NS_BLOCKS_AVAILABLE
typedef void (^handleInitialized)(void);
typedef void (^handleError)(id);
#endif

@interface AsyncStreamReader : NSObject

@property (strong, nonatomic, readonly)  NSString *stream;
@property (strong, nonatomic, readonly)  SRConnection *connection;
@property (strong, nonatomic, readonly)  SRServerSentEventsTransport *transport;
@property (copy)  handleInitialized initializeCallback;
@property (copy)  handleError errorCallback;
@property (assign, nonatomic, readonly)  BOOL reading;

- (id)initWithStream:(id)steam connection:(SRConnection *)connection transport:(SRServerSentEventsTransport *)transport initializeCallback:(void(^)(void))initializeCallback errorCallback:(void(^)(id))errorCallback;

- (void)startReading;
- (void)stopReading;
- (void)readLoop;
- (void)processChunks:(NSScanner *)scanner;
- (BOOL)tryParseEvent:(NSString *)line sseEvent:(SseEvent **)sseEvent;

@end

@implementation AsyncStreamReader

@synthesize stream = _stream;
@synthesize connection = _connection;
@synthesize transport = _transport;
@synthesize initializeCallback = _initializeCallback;
@synthesize errorCallback = _errorCallback;
@synthesize reading = _reading;

- (id)initWithStream:(id)steam connection:(SRConnection *)connection transport:(SRServerSentEventsTransport *)transport initializeCallback:(void(^)(void))initializeCallback errorCallback:(void(^)(id))errorCallback
{
    if (self = [super init])
    {
        _stream = steam;
        _connection = connection;
        _transport = transport;
        _initializeCallback = initializeCallback;
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

- (void)readLoop
{
    if(!_reading)
    {
        return;
    }
    
    NSScanner *scanner = [[NSScanner alloc] initWithString:_stream];
    [self processChunks:scanner];
}

- (void)processChunks:(NSScanner *)scanner
{
    while (_reading && ![scanner isAtEnd]) 
    {
        NSString *line = nil;
        [scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&line];
        
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
                _connection.messageId = [NSNumber numberWithInteger:[sseEvent.data integerValue]];
                break;
            }
            case Data:
            {
                if([sseEvent.data isEqualToString:@"initialized"])
                {
                    if(_initializeCallback)
                    {
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

@interface SRServerSentEventsTransport ()

- (void)openConnection:(SRConnection *)connection data:(NSString *)data initializeCallback:(void(^)(void))initializeCallback errorCallback:(void(^)(id))errorCallback;

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

- (void)onStart:(SRConnection *)connection data:(NSString *)data initializeCallback:(void(^)(void))initializeCallback errorCallback:(void(^)(id))errorCallback
{
    [self openConnection:connection data:data initializeCallback:initializeCallback errorCallback:errorCallback];
}

- (void)openConnection:(SRConnection *)connection data:(NSString *)data initializeCallback:(void(^)(void))initializeCallback errorCallback:(void(^)(id))errorCallback
{
    NSString *url = connection.url;

    url = [url stringByAppendingFormat:@"%@",[self getReceiveQueryString:connection data:data]];

    [SRHttpHelper postAsync:url requestPreparer:^(ASIHTTPRequest * request)
    {
        [self prepareRequest:request forConnection:connection];

        [request addRequestHeader:@"Accept" value:@"text/event-stream"];
         
        if(connection.messageId != nil)
        {
            [request addRequestHeader:@"Last-Event-ID" value:[connection.messageId stringValue]];
        }
    }
    continueWith:^(id response) {
#if DEBUG
         NSLog(@"openConnectionDidReceiveResponse: %@",response);
#endif
         BOOL isFaulted = ([response isKindOfClass:[NSError class]] || 
                           [response isEqualToString:@""] || response == nil ||
                           [response isEqualToString:@"null"]);
         if(isFaulted)
         {
             if(errorCallback)
             {
                 errorCallback(response);
             }
         }
         else
         {
             //Get the response stream and read it for messages
             AsyncStreamReader *reader = [[AsyncStreamReader alloc] initWithStream:response connection:connection transport:self initializeCallback:initializeCallback errorCallback:errorCallback];
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