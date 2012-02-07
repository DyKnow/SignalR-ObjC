//
//  SRConnection.h
//  SignalR
//
//  Created by Alex Billingsley on 10/17/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRClientTransport.h"

@class SRConnection;

@protocol SRConnectionDelegate<NSObject>
@optional 
- (void)SRConnectionDidOpen:(SRConnection *)connection;
- (void)SRConnectionDidReconnect:(SRConnection *)connection;
- (void)SRConnection:(SRConnection *)connection didReceiveData:(NSString *)data;
- (void)SRConnectionDidClose:(SRConnection *)connection;
- (void)SRConnection:(SRConnection *)connection didReceiveError:(NSError *)error;

@end

#if NS_BLOCKS_AVAILABLE
typedef void (^onStarted)();
typedef NSString* (^onSending)();
typedef void (^onReceived)(NSString *);
typedef void (^onError)(NSError *);
typedef void (^onClosed)();
typedef void (^onReconnected)();
#endif

@interface SRConnection : NSObject 

@property (copy) onStarted started;
@property (copy) onReceived received;
@property (copy) onError error; 
@property (copy) onClosed closed;
@property (copy) onReconnected reconnected;
@property (strong, nonatomic, readwrite) NSURLCredential *credentials;
@property (strong, nonatomic, readwrite) NSMutableArray *groups;
@property (copy) onSending sending;
@property (strong, nonatomic, readwrite) NSString *url;
@property (assign, nonatomic, readonly, getter=isActive) BOOL active;
@property (strong, nonatomic, readwrite) NSNumber *messageId;
@property (strong, nonatomic, readwrite) NSString *connectionId;
@property (strong, nonatomic, readwrite) NSMutableDictionary *items;
@property (strong, nonatomic, readonly) NSString *queryString;
@property (assign, nonatomic, readonly) BOOL initialized;

@property (nonatomic, assign) id<SRConnectionDelegate> delegate;

+ (SRConnection *)connectionWithURL:(NSString *)URL;
+ (SRConnection *)connectionWithURL:(NSString *)url query:(NSDictionary *)queryString;
+ (SRConnection *)connectionWithURL:(NSString *)url queryString:(NSString *)queryString;
- (id)initWithURL:(NSString *)url;
- (id)initWithURL:(NSString *)url query:(NSDictionary *)queryString;
- (id)initWithURL:(NSString *)url queryString:(NSString *)queryString;

- (void)start;
- (void)start:(id <SRClientTransport>)transport;
- (void)negotiate;
- (void)send:(NSString *)message;
- (void)send:(NSString *)message continueWith:(void (^)(id response))block;
- (void)stop;
- (void)didReceiveData:(NSString *)data;
- (void)didReceiveError:(NSError *)ex;
- (void)didReconnect;

- (void)prepareRequest:(id)request;
- (NSString *)createUserAgentString:(NSString *)client;

@end
