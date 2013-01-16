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
#import "SRConnectionState.h"
#import "SRHttpClient.h"
#import "SRRequest.h"

@class SRConnection;

/**
 * The delegate of a `SRConnection` object can optionally adapt the `SRConnectionDelegate` protocol. 
 * The methods of the protocol allow the delegate to receive update when events occur on the `SRConnection` object some of these event include; 
 * the connection being opened, reconnected, closed and when data or an error is received.
 */
@protocol SRConnectionDelegate<NSObject>
@optional 

/**
 * Called when the `SRConnection` is opened
 *
 * @param connection the `SRConnection` object dispatching the event
 */
- (void)SRConnectionDidOpen:(SRConnection *)connection;

/**
 * Called when the `SRConnection` is reconnecting
 *
 * @param connection the `SRConnection` object dispatching the event
 */
- (void)SRConnectionWillReconnect:(SRConnection *)connection;

/**
 * Called when the `SRConnection` is reconnected
 *
 * @param connection the `SRConnection` object dispatching the event
 */
- (void)SRConnectionDidReconnect:(SRConnection *)connection;

/**
 * Called when the `SRConnection` receives data
 *
 * @param connection the `SRConnection` object dispatching the event
 * @param data the data received
 */
- (void)SRConnection:(SRConnection *)connection didReceiveData:(NSString *)data;

/**
 * Called when the `SRConnection` is closed
 *
 * @param connection the `SRConnection` object dispatching the event
 */
- (void)SRConnectionDidClose:(SRConnection *)connection;

/**
 * Called when the `SRConnection` receives an error
 *
 * @param connection the `SRConnection` object dispatching the event
 * @param error the `NSError` received
 */
- (void)SRConnection:(SRConnection *)connection didReceiveError:(NSError *)error;

- (void)SRConnection:(SRConnection *)connection didChangeState:(connectionState)oldState newState:(connectionState)newState;

@end

typedef void (^onStarted)();
typedef void (^onReceived)(NSString *);
typedef void (^onError)(NSError *);
typedef void (^onClosed)();
typedef void (^onReconnecting)();
typedef void (^onReconnected)();
typedef void (^onStateChanged)(connectionState);

/**
 * An `SRConnection` object provides support to open a persistent connection with a SignalR Server.
 *
 * `SRConnection`’s delegate methods—defined by the `SRConnectionDelegate` protocol allows an object to receive informational callbacks when events occur on the `SRConnection` object
 */
@interface SRConnection : NSObject 

///-------------------------------
/// @name Properties
///-------------------------------

/**
 * Occurs when the SRConnection is started.
 */
@property (copy) onStarted started;

/**
 * Occurs when the SRConnection has received data from the server.
 */
@property (copy) onReceived received;

/**
 * Occurs when the SRConnection has encountered an error.
 */
@property (copy) onError error; 

/**
 * Occurs when the SRConnection is stopped.
 */
@property (copy) onClosed closed;

/*
 * Occurs when the SRConnection starts reconnecting after an error.
 */
@property (copy) onReconnecting reconnecting;

/**
 * Occurs when the SRConnection successfully reconnects after a timeout.
 */
@property (copy) onReconnected reconnected;

/*
 * Occurs when the SRConnection state changes.
 */
@property (copy) onStateChanged stateChanged;


@property (strong, nonatomic, readonly) NSMutableDictionary *headers;

/*
 * Gets or sets authentication information for the connection.
 */
@property (strong, nonatomic, readwrite) NSURLCredential *credentials;

/*
 * Gets of sets proxy information for the connection.
 */
//@property (strong, nonatomic, readwrite) id proxy; TODO: Add the proxy information??

/*
 * Gets the groups for the connection.
 */
@property (strong, nonatomic, readwrite) NSMutableArray *groups;

/*
 * Gets the url for the connection.
 */
@property (strong, nonatomic, readonly) NSString *url;

/*
 * Gets or sets the last message id for the connection.
 */
@property (strong, nonatomic, readwrite) NSString *messageId;

/*
 * Gets or sets the connection id for the connection.
 */
@property (strong, nonatomic, readwrite) NSString *connectionId;

/*
 * Gets a dictionary for storing state for a the connection.
 */
@property (strong, nonatomic, readonly) NSMutableDictionary *items;

/*
 * Gets the querystring specified in the ctor.
 */
@property (strong, nonatomic, readonly) NSString *queryString;

/*
 * Gets the current <see cref="ConnectionState"/> of the connection.
 */
@property (assign, nonatomic, readonly) connectionState state;

@property (nonatomic, assign) id<SRConnectionDelegate> delegate;

///-------------------------------
/// @name Initializing an SRConnection Object
///-------------------------------

/**
 * A convenience method for initWithURLString:(NSString *)url;
 *
 * @param URL the endpoint to initialize the new connection to
 * @return an `SRConnection` object 
 */
+ (id)connectionWithURL:(NSString *)URL;

/**
 * A convenience method for initWithURLString:(NSString *)url query:(NSDictionary *)queryString;
 *
 * @param url the endpoint to initialize the new connection to
 * @param queryString an `NSDictionary` representation of a custom query string to be appended to the `SRConnection` endpoint
 * @return an `SRConnection` object 
 */
+ (id)connectionWithURL:(NSString *)url query:(NSDictionary *)queryString;

/**
 * A convenience method for initWithURLString:(NSString *)url queryString:(NSString *)queryString;;
 *
 * @param url the endpoint to initialize the new connection to
 * @param queryString an `NSString` representation of a custom query string to be appended to the `SRConnection` endpoint
 * @warning *Important* Url cannot contain a QueryString directly. Namely the string should not contain the prefix '?' It is recommended that (SRConnection *)connectionWithURL:(NSString *)url query:(NSDictionary *)queryString; is used instead
 * @return an `SRConnection` object 
 */
+ (id)connectionWithURL:(NSString *)url queryString:(NSString *)queryString;

/**
 * Initializes a new instance of the `SRConnection` class
 
 * @param url the endpoint to initialize the new connection to
 * @return an `SRConnection` object 
 */
- (id)initWithURLString:(NSString *)url;

/**
 * Initializes a new instance of the `SRConnection` class
 *
 * @param url the endpoint to initialize the new connection to
 * @param queryString an `NSDictionary` representation of a custom query string to be appended to the `SRConnection` endpoint
 * @return an `SRConnection` object 
 */
- (id)initWithURLString:(NSString *)url query:(NSDictionary *)queryString;

/**
 * Initializes a new instance of the `SRConnection` class
 *
 * @param url the endpoint to initialize the new connection to
 * @param queryString an `NSString` representation of a custom query string to be appended to the `SRConnection` endpoint
 * @warning *Important* Url cannot contain a QueryString directly. Namely the string should not contain the prefix '?' It is recommended that (id)initWithURL:(NSString *)url query:(NSDictionary *)queryString;; is used instead
 * @return an `SRConnection` object 
 */
- (id)initWithURLString:(NSString *)url queryString:(NSString *)queryString;

///-------------------------------
/// @name Connection Management
///-------------------------------

/**
 * Starts the `SRConnection`.
 */
- (void)start;

/**
 * Starts the `SRConnection`.
 *
 * @param httpClient the httpClient to use for the connection
 */
- (void)startHttpClient:(id <SRHttpClient>)httpClient;

/**
 * Starts the `SRConnection`
 * @param transport the transport to use for the connection
 */
- (void)start:(id <SRClientTransport>)transport;

- (BOOL)changeState:(connectionState)oldState toState:(connectionState)newState;

/**
 * Stops the `SRConnection` and sends an abort message to the server.
 */
- (void)stop;

/*
 * Stops the `SRConnection` without sending an abort message to the server.
 */
- (void)disconnect;

///-------------------------------
/// @name Sending Data
///-------------------------------

- (NSString *)onSending;

/**
 * Sends data asynchronously over the connection.
 *
 * @warning *Important* Start must be called before sending data
 *
 * @param object a JSON stringifable object to send
 */
- (void)send:(id)object;

/**
 * Sends data asynchronously over the connection.
 *
 * @warning *Important* Start must be called before sending data
 *
 * @param object a JSON stringifable object to send
 * @param block the callback to be called once the message is sent.
 */
- (void)send:(id)object continueWith:(void (^)(id response))block;

///-------------------------------
/// @name Receiving Data
///-------------------------------

/**
 * Called when the connection receives new data
 * dispatches the response to either the `SRConnectionDelegate` by calling [self.delegate SRConnection:self didReceiveData:message];
 * or to the self.received callback 
 *
 * @param data the data received from the server
 */
- (void)didReceiveData:(NSString *)data;

/**
 * Called when the connection receives an error
 * dispatches the error to either the `SRConnectionDelegate` by calling [self.delegate SRConnection:self didReceiveError:ex];
 * or to the self.error callback 
 *
 * @param ex the error received from the server
 */
- (void)didReceiveError:(NSError *)ex;

/**
 * Called when the connection reconnects after a server side timeout
 * dispatches the reconnect to either the `SRConnectionDelegate` by calling [self.delegate SRConnectionDidReconnect:self];
 * or to the self.reconnected callback 
 */
- (void)didReconnect;
 
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

/**
 * Sets the user agent, crediential information and other relevant header values on each connection
 *
 * @param request The `id <SRRequest>` that will be sent to the server
 */
- (void)prepareRequest:(id <SRRequest>)request;

/**
 * Generates the client UserAgent header field
 *
 * @param client the client name 
 * @return The user agent will be of the form client/version (DeviceModel/DeviceVersion) 
 */
- (NSString *)createUserAgentString:(NSString *)client;

- (BOOL)ensureReconnecting;

@end
