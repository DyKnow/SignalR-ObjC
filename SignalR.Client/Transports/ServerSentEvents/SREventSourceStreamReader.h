//
//  SREventSourceStreamReader.h
//  SignalR.Samples
//
//  Created by Alex Billingsley on 6/8/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SRConnection;
@class SRChunkBuffer;
@class SRServerSentEventsTransport;

typedef void (^onInitialized)(void);
typedef void (^onClose)(void);

@interface SREventSourceStreamReader : NSObject <NSStreamDelegate>

@property (strong, nonatomic, readwrite)  NSOutputStream *stream;
@property (strong, nonatomic, readonly)  SRChunkBuffer *buffer;
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

@end
