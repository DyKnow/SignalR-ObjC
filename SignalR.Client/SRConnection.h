//
//  SRConnection.h
//  SignalR
//
//  Created by Alex Billingsley on 10/17/11.
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

#import <Foundation/Foundation.h>
#import "SRClientTransport.h"

@class SRConnection;

@protocol SRConnectionDelegate<NSObject>
@optional 
- (void)SRConnectionDidOpen:(SRConnection *)connection;
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
#endif

@interface SRConnection : NSObject 

@property (assign, nonatomic, readwrite) NSInteger initializedCalled;
@property (copy) onStarted started;
@property (copy) onReceived received;
@property (copy) onError error; 
@property (copy) onClosed closed;
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
- (void)send:(NSString *)message;
- (void)send:(NSString *)message continueWith:(void (^)(id response))block;
- (void)stop;
- (void)didReceiveData:(NSString *)data;
- (void)didReceiveError:(NSError *)ex;

- (void)prepareRequest:(id)request;
- (NSString *)createUserAgentString:(NSString *)client;

@end
