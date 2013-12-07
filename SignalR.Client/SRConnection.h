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
#import "SRConnectionDelegate.h"
#import "SRConnectionInterface.h"
#import "SRConnectionState.h"

@class SRConnection;

typedef void (^onStarted)();
typedef void (^onReceived)(id);
typedef void (^onError)(NSError *);
typedef void (^onClosed)();
typedef void (^onReconnecting)();
typedef void (^onReconnected)();
typedef void (^onStateChanged)(connectionState);
typedef void (^onConnectionSlow)();

@interface SRConnection : NSObject <SRConnectionInterface>

///-------------------------------
/// @name Properties
///-------------------------------

@property (copy) onStarted started;
@property (copy) onReceived received;
@property (copy) onError error; 
@property (copy) onClosed closed;
@property (copy) onReconnecting reconnecting;
@property (copy) onReconnected reconnected;
@property (copy) onStateChanged stateChanged;
@property (copy) onConnectionSlow connectionSlow;

@property (nonatomic, assign) id<SRConnectionDelegate> delegate;

///-------------------------------
/// @name Initializing an SRConnection Object
///-------------------------------

+ (instancetype)connectionWithURL:(NSString *)URL;
+ (instancetype)connectionWithURL:(NSString *)url query:(NSDictionary *)queryString;
+ (instancetype)connectionWithURL:(NSString *)url queryString:(NSString *)queryString;
- (instancetype)initWithURLString:(NSString *)url;
- (instancetype)initWithURLString:(NSString *)url query:(NSDictionary *)queryString;
- (instancetype)initWithURLString:(NSString *)url queryString:(NSString *)queryString;

///-------------------------------
/// @name Connection Management
///-------------------------------

- (void)start;
- (void)start:(id <SRClientTransportInterface>)transport;
- (void)stop:(NSNumber *)timeout;
- (void)didClose;

///-------------------------------
/// @name Sending Data
///-------------------------------

- (NSString *)onSending;

///-------------------------------
/// @name Preparing Requests
///-------------------------------

 /**
  * Adds an HTTP header to the receiver’s HTTP header dictionary.
  *
  * @param value The value for the header field.
  * @param field the name of the header field.
  **/
- (void)addValue:(NSString *)value forHTTPHeaderField:(NSString *)field;

@end
