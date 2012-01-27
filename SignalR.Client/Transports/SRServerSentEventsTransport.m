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
#pragma mark AsyncStreamReader

#if NS_BLOCKS_AVAILABLE
typedef void (^onInitialized)(void);
#endif

@interface AsyncStreamReader : NSObject

@property (strong, nonatomic, readonly)  NSString *stream;
@property (strong, nonatomic, readonly)  SRConnection *connection;
@property (copy) onInitialized initializeCallback;
@property (strong, nonatomic, readonly)  SRServerSentEventsTransport *transport;
@property (assign, nonatomic, readonly)  BOOL reading;

- (id)initWithStream:(id)steam connection:(SRConnection *)connection transport:(SRServerSentEventsTransport *)transport;

- (void)startReading;
- (void)stopReading;
- (void)readLoop;
- (void)processChunks:(NSScanner *)scanner;
- (BOOL)tryParseEvent:(NSString *)line sseEvent:(SseEvent **)sseEvent;

@end

@implementation AsyncStreamReader

@synthesize stream = _stream;
@synthesize connection = _connection;
@synthesize initializeCallback = _initializeCallback;
@synthesize transport = _transport;
@synthesize reading = _reading;

- (id)initWithStream:(id)steam connection:(SRConnection *)connection transport:(SRServerSentEventsTransport *)transport
{
    if (self = [super init])
    {
        _stream = steam;
        _connection = connection;
        _transport = transport;
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
                           [httpResponse.response isEqualToString:@""] || httpResponse.response == nil ||
                           [httpResponse.response isEqualToString:@"null"]);
        
        @try 
        {
            if([httpResponse.response isKindOfClass:[NSString class]])
            {
                if(!isFaulted)
                {
                    [self onMessage:connection response:httpResponse.response];
                }
            }
        }
        @finally 
        {
            BOOL requestAborted = NO;
            
            if(isFaulted)
            {
                if([httpResponse.response isKindOfClass:[NSError class]])
                {
                    if([httpResponse.response code] >= 500)
                    {
                        if (errorCallback && connection.initialized ==NO)
                        {
                            SRErrorByReferenceBlock errorBlock = ^(NSError ** error)
                            {
                                *error = httpResponse.response;
                            };
                            errorCallback(errorBlock);
                        }
                    }
                    else
                    {
                        //Figure out if the request is aborted
                        requestAborted = [self isRequestAborted:httpResponse.response];
                        
                        //Sometimes a connection might have been closed by the server before we get to write anything
                        //So just try again and don't raise an error
                        //TODO: check for IOException
                        if(!requestAborted) //&& !(exception is IOExeption))
                        {
                            //Raise Error
                            [connection didReceiveError:httpResponse.response];
                            
                            //If the connection is still active after raising the error wait 2 seconds 
                            //before polling again so we arent hammering the server
                            if(connection.isActive)
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
                            }
                        }
                    }
                }
            }
            else
            {
                //Get the response stream and read it for messages
                AsyncStreamReader *reader = [[AsyncStreamReader alloc] initWithStream:httpResponse.response connection:connection transport:self];
                reader.initializeCallback = ^(){
                    if(initializeCallback != nil)
                    {
                        initializeCallback();
                    }
                };
                
                [reader startReading];
                
                //Set the reader for this connection
                [connection.items setObject:reader forKey:kReaderKey];
            }
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