//
//  SRHubInvocation.h
//  SignalR
//
//  Created by Alex Billingsley on 11/7/11.
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
#import "SRSerializable.h"
#import "SRDeserializable.h"

/**
 * An `SRHubInvocation` object defines the interface for invoking methods on the SignalR Client using a Hubs implementation
 */
@interface SRHubInvocation : NSObject <SRDeserializable, SRSerializable>

///-------------------------------
/// @name Properties
///-------------------------------

@property (strong, nonatomic, readwrite) NSString *callbackId;

/**
 * The `NSString` object corresponding to the hub to preform an invocation on
 */
@property (strong, nonatomic, readwrite) NSString *hub;

/**
 * The `NSString` object corresponding to the method to invoke on the hub
 */
@property (strong, nonatomic, readwrite) NSString *method;

/**
 * The `NSMutableArray` object corresponding to the arguments to be passed as part of the invocation
 */
@property (strong, nonatomic, readwrite) NSMutableArray *args;

/**
 * The `NSMutableDictionary` object corresponding to the client state
 */
@property (strong, nonatomic, readwrite) NSMutableDictionary *state;

@end
