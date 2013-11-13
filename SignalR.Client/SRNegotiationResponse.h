//
//  SRNegotiationResponse.h
//  SignalR
//
//  Created by Alex Billingsley on 11/1/11.
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
#import "SRDeserializable.h"

/**
 *  An `SRNegotiationResponse` object provides access to the negotiation response object received from the server 
 */
@interface SRNegotiationResponse : NSObject <SRDeserializable>

///-------------------------------
/// @name Properties
///-------------------------------

/**
 * An `NSString` object representing the connectionId belonging to the current client
 */
@property (strong, nonatomic, readonly) NSString *connectionId;

@property (strong, nonatomic, readonly) NSString *connectionToken;

/**
 * An `NSString` object representing the app relative server url the client should use for all subsequent requests
 */
@property (strong, nonatomic, readonly) NSString *url;

/**
 * An `NSString` object representing the protocol version the server is using.
 */
@property (strong, nonatomic, readonly) NSString *protocolVersion;

@property (strong, nonatomic, readonly) NSNumber *disconnectTimeout;

@property (assign, nonatomic, readonly) BOOL tryWebSockets;

@property (strong, nonatomic, readonly) NSNumber *keepAliveTimeout;

@property (strong, nonatomic, readonly) NSNumber *transportConnectTimeout;

@end
