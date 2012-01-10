//
//  SRConnection.h
//  SignalR
//
//  Created by Alex Billingsley on 10/17/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SRClientTransport.h"
#import "ASIHTTPRequest.h"

@class SRConnection;

@protocol SRConnectionDelegate<NSObject>
@optional 
- (void)SRConnectionDidOpen:(SRConnection *)connection;
- (void)SRConnection:(SRConnection *)connection didReceiveData:(NSString *)data;
- (void)SRConnectionDidClose:(SRConnection *)connection;
- (void)SRConnection:(SRConnection *)connection didReceiveError:(NSError *)error;

@end

#if NS_BLOCKS_AVAILABLE
typedef NSString* (^onSending)();
typedef void (^onReceived)(NSString *);
typedef void (^onError)(NSError *);
typedef void (^onClosed)();
#endif

@interface SRConnection : NSObject 

@property (copy) onReceived received;
@property (copy) onError error; 
@property (copy) onClosed closed;
//TODO: Credentials
//@property (strong, nonatomic, readwrite) id credentials;
@property (strong, nonatomic, readwrite) NSMutableArray *groups;
@property (copy) onSending sending;
@property (strong, nonatomic, readwrite) NSString *url;
@property (assign, nonatomic, readonly, getter=isActive) BOOL active;
@property (strong, nonatomic, readwrite) NSNumber *messageId;
@property (strong, nonatomic, readwrite) NSString *connectionId;
@property (strong, nonatomic, readwrite) NSMutableDictionary *items;

@property (nonatomic, assign) id<SRConnectionDelegate> delegate;

+ (SRConnection *)connectionWithURL:(NSString *)URL;
- (id)initWithURL:(NSString *)url;

- (void)start;
- (void)start:(id <SRClientTransport>)transport;
- (void)send:(NSString *)message;
- (void)send:(NSString *)message onCompletion:(void(^)(id))block;
- (void)stop;
- (void)didReceiveData:(NSString *)data;
- (void)didReceiveError:(NSError *)ex;

- (void)prepareRequest:(ASIHTTPRequest *)request;
- (NSString *)createUserAgentString:(NSString *)client;

@end
