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

@end

typedef void (^onStarted)();
typedef void (^onReceived)(NSString *);
typedef void (^onError)(NSError *);
typedef void (^onClosed)();
typedef void (^onReconnected)();

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
 * A block to be called when the connection's underlying transport is `initialized` the first time
 */
@property (copy) onStarted started;

/**
 * A block to be called when the connection's underlying transport receives new data
 */
@property (copy) onReceived received;

/**
 * A block to be called when the connection's underlying transport receives a error
 */
@property (copy) onError error; 

/**
 * A block to be called when the connection's underlying transport is closed
 */
@property (copy) onClosed closed;

/**
 * A block to be called when the connection's underlying transport is reconnected
 */
@property (copy) onReconnected reconnected;

/**
 * The authentication credential to be applied to each request
 * Support is limited to HTTP Basic Authentication
 */
@property (strong, nonatomic, readwrite) NSURLCredential *credentials;

/**
 * A `NSMutableArray` of the connected groups
 */
@property (strong, nonatomic, readwrite) NSMutableArray *groups;

/**
 * The endpoint at which the connection is initialized to
 */
@property (strong, nonatomic, readwrite) NSString *url;

/**
 * An `NSString` representing the current message id 
 */
@property (strong, nonatomic, readwrite) NSString *messageId;

/**
 * An `NSString` representing the current connectionId established during negotiation 
 */
@property (strong, nonatomic, readwrite) NSString *connectionId;

/**
 * An `NSMutableDictionary` containing objects that need to be persisted by the underlying transport for example the last httprequest.
 */
@property (strong, nonatomic, readwrite) NSMutableDictionary *items;

/**
 * An `NSString` representing the custom query string to be applied to each request
 */
@property (strong, nonatomic, readonly) NSString *queryString;

@property (assign, nonatomic, readwrite) connectionState state;

/**
 * An `NSMutableDictionary` representing the headers to be applied to each request 
 */
@property (strong, nonatomic, readonly) NSMutableDictionary *headers;

/**
 * The object that acts as the delegate of the receiving `SRConnection`.
 */
@property (nonatomic, assign) id<SRConnectionDelegate> delegate;

///-------------------------------
/// @name Initializing an SRConnection Object
///-------------------------------

/**
 * A convenience method for initWithURLString:(NSString *)url;
 *
 * <code>
 *  SRConnection *connection = [SRConnection connectionWithURL:@"http://mysite/echo"];
 * </code>
 *
 * @param URL the endpoint to initialize the new connection to
 * @return an `SRConnection` object 
 */
+ (id)connectionWithURL:(NSString *)URL;

/**
 * A convenience method for initWithURLString:(NSString *)url query:(NSDictionary *)queryString;
 *
 * <code>
 *  SRConnection *connection = [SRConnection connectionWithURL:@"http://mysite/echo"];
 * </code>
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
 * Initializes a new `SRConnection` object at the specified URL
 *
 * <code>
 *  SRConnection *connection = [[SRConnection alloc] initWithURLString:@"http://mysite/echo"];
 * </code>
 *
 * @param url the endpoint to initialize the new connection to
 * @return an `SRConnection` object 
 */
- (id)initWithURLString:(NSString *)url;

/**
 * Initializes a new `SRConnection` object at the specified URL
 *
 * @param url the endpoint to initialize the new connection to
 * @param queryString an `NSDictionary` representation of a custom query string to be appended to the `SRConnection` endpoint
 * @return an `SRConnection` object 
 */
- (id)initWithURLString:(NSString *)url query:(NSDictionary *)queryString;

/**
 * Initializes a new `SRConnection` object at the specified URL
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
 * Starts the connection using SRAutoTransport
 *
 * sets `active` to YES
 */
- (void)start;

- (void)startHttpClient:(id <SRHttpClient>)httpClient;

/**
 * Starts the connection
 *
 * sets `active` to YES
 *
 * @param transport the transport to use for the connection
 */
- (void)start:(id <SRClientTransport>)transport;

/**
 * Perfromed prior to starting the underlying transport, a negoitate establishes the initial connection with the server
 * by making a request to url/negotiate a sucessful response returns an SRNegotiationResponse object which establishes the connectionId
 * at which time the underlying transport will be started.
 * dispatches the opened event to either the `SRConnectionDelegate` by calling [self.delegate SRConnectionDidOpen:self];
 * or to the self.started callback once the transport is successfully initialized
 *
 * @param transport the transport to use during negotiation
 */
- (void)negotiate:(id <SRClientTransport>)transport;

- (BOOL)changeState:(connectionState)oldState toState:(connectionState)newState;

/**
 * Stops the connection
 * dispatches the closed event to either the `SRConnectionDelegate` by calling [self.delegate SRConnectionDidClose:self];
 * or to the self.closed callback 
 * sets `active` and `initialized` to NO
 */
- (void)stop;

///-------------------------------
/// @name Sending Data
///-------------------------------

- (NSString *)onSending;

/**
 * Sends data over the connection.
 * calls [self send:message continueWith:nil];
 *
 * @param object a JSON stringifable object to send
 */
- (void)send:(id)object;

/**
 * Sends data over the connection.
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

@end
