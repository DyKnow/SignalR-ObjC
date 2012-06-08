//
//  SRClientTransport.h
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

@class SRConnection;
@class SRNegotiationResponse;

/**
 * `SRClientTransport` defines the protocol each Client Transport should conform to
 **/
@protocol SRClientTransport <NSObject>

- (void)negotiate:(SRConnection *)connection continueWith:(void (^)(SRNegotiationResponse *response))block;

/**
 * Opens a connection to the server for the active transport
 *
 * @param connection the `SRConnection` to start the transport on
 * @param data the data to send when starting the transport on, may be nil
 * @param block the block to be called once start finishes, block may be nil
 */
- (void)start:(SRConnection *)connection withData:(NSString *)data continueWith:(void (^)(id response))block;

/**
 * Sends data to the server for the active transport
 *
 * @param connection the `SRConnection` to send the message on
 * @param data the data to send the server
 * @param block the block to be called once send finishes, block may be nil
 */
- (void)send:(SRConnection *)connection withData:(NSString *)data continueWith:(void (^)(id response))block;

/**
 * Stops the active transport from receiving data from the server
 *
 * @param connection the `SRConnection` owning the transport that should be stopped
 */
- (void)stop:(SRConnection *)connection;

@end