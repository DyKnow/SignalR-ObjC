//
//  SRClientTransportInterface.h
//  SignalR
//
//  Created by Alex Billingsley on 10/28/11.
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

@protocol SRConnectionInterface;
@class SRNegotiationResponse;

/**
 * `SRClientTransportInterface` defines the protocol each Client Transport should conform to
 **/
@protocol SRClientTransportInterface <NSObject>

@property (strong, nonatomic, readonly) NSString *name;
@property (assign, nonatomic, readonly) BOOL supportsKeepAlive;

- (void)negotiate:(id <SRConnectionInterface>)connection connectionData:(NSString *)connectionData completionHandler:(void (^)(SRNegotiationResponse *response, NSError *error))block;

/**
 * Opens a connection to the server for the active transport
 *
 * @param connection the `SRConnectionInterface` to start the transport on
 * @param data the data to send when starting the transport on, may be nil
 * @param block the block to be called once start finishes, block may be nil
 */
- (void)start:(id <SRConnectionInterface>)connection connectionData:(NSString *)connectionData completionHandler:(void (^)(id response, NSError *error))block;

/**
 * Sends data to the server for the active transport
 *
 * @param connection the `SRConnectionInterface` to send the message on
 * @param data the data to send the server
 * @param block the block to be called once send finishes, block may be nil
 */
- (void)send:(id <SRConnectionInterface>)connection data:(NSString *)data connectionData:(NSString *)connectionData completionHandler:(void (^)(id response, NSError *error))block;

/**
 * Stops the active transport from receiving data from the server
 *
 * @param connection the `SRConnectionInterface` owning the transport that should be stopped
 * @param timeout the allotted time for informing the server about the aborted connection. <= 0 means do not contact server 
 */
- (void)abort:(id <SRConnectionInterface>)connection timeout:(NSNumber *)timeout connectionData:(NSString *)connectionData;

- (void)lostConnection:(id <SRConnectionInterface>)connection;

@end
