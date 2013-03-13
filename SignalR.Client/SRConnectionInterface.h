//
//  SRConnectionInterface.h
//  SignalR
//
//  Created by Alex Billingsley on 2/16/13.
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
#import "SRConnectionState.h"
#import "SRRequest.h"

@protocol SRConnectionInterface <NSObject>

///-------------------------------
/// @name Properties
///-------------------------------

@property (strong, nonatomic, readwrite) NSString *messageId;
@property (strong, nonatomic, readwrite) NSString *groupsToken;
@property (strong, nonatomic, readonly) NSString *connectionToken;
@property (strong, nonatomic, readonly) NSMutableDictionary *items;
@property (strong, nonatomic, readonly) NSString *connectionId;
@property (strong, nonatomic, readonly) NSString *url;
@property (strong, nonatomic, readonly) NSString *queryString;
@property (assign, nonatomic, readonly) connectionState state;
@property (strong, nonatomic, readwrite) NSURLCredential *credentials;
@property (strong, nonatomic, readwrite) NSMutableDictionary *headers;

///-------------------------------
/// @name Connection Management
///-------------------------------

- (BOOL)changeState:(connectionState)oldState toState:(connectionState)newState;
- (void)stop;
- (void)disconnect;

///-------------------------------
/// @name Sending Data
///-------------------------------

- (void)send:(id)object;
- (void)send:(id)object completionHandler:(void (^)(id response))block;

///-------------------------------
/// @name Receiving Data
///-------------------------------

- (void)didReceiveData:(NSString *)data;
- (void)didReceiveError:(NSError *)error;
- (void)willReconnect;
- (void)didReconnect;

///-------------------------------
/// @name Preparing Requests
///-------------------------------

- (void)prepareRequest:(id <SRRequest>)request;

@end
