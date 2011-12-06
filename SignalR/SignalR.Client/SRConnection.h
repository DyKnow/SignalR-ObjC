//
//  SRConnection.h
//  SignalR
//
//  Created by Alex Billingsley on 10/17/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HttpHelper.h"

@class SRConnection;

@protocol SRConnectionDelegate<NSObject>
@optional 
- (void)SRConnectionDidOpen:(SRConnection *)connection;
- (void)SRConnection:(SRConnection *)connection didReceiveData:(NSString *)data;
- (void)SRConnectionDidClose:(SRConnection *)connection;
- (void)SRConnection:(SRConnection *)connection didReceiveError:(NSError *)error;

@end

typedef NSString* (^onSending)();
typedef void (^onReceived)(NSString *);
typedef void (^onError)(NSError *);
typedef void (^onClosed)();

@interface SRConnection : NSObject 

@property (nonatomic, assign) id<SRConnectionDelegate> delegate;

@property (copy) onSending sending;
@property (copy) onReceived received;
@property (copy) onError error; 
@property (copy) onClosed closed;

@property (nonatomic, readonly, strong) id transport;

@property (nonatomic, strong) NSString *url;
@property (nonatomic, getter=isActive) BOOL active;
@property (nonatomic, strong) NSNumber *messageId;
@property (nonatomic, strong) NSString *connectionId;
@property (nonatomic, strong) NSMutableArray *groups;
@property (nonatomic, strong) NSString *assemblyVersion;

@property (nonatomic, strong) NSString *appRelativeUrl;
@property (nonatomic, strong) NSString *data;

+ (SRConnection *)connectionWithURL:(NSString *)URL;
- (id)initWithURL:(NSString *)url;
- (void)start;
- (void)send:(NSString *)message;
- (void)send:(NSString *)message onCompletion:(void(^)(SRConnection *, id))block;
- (void)stop;
- (void)didReceiveData:(NSString *)data;
- (void)didReceiveError:(NSError *)ex;
- (NSString *)createUserAgentString:(NSString *)client;

@end
