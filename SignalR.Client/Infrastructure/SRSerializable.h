//
//  SRSerializable.h
//  SignalR
//
//  Created by Alex Billingsley on 6/6/12.
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

/**
 * An `SRSerializable` defines the protocol that should be enforced if an NSObject is intended to be sent to a transport
 *
 * It should be noted that while all functions are optional at least one should be used for auto detected JSON serialization to work properly
 */
@protocol SRSerializable <NSObject>

@optional

///-------------------------------
/// @name JSON Serialization
///-------------------------------

/**
 * Conforms to SBJson (aka json-framework) allowing `NSObjects` to be serialized to JSON
 */
- (id) proxyForJson;

/**
 * Conforms to YAJL allowing `NSObjects` to be serialized to JSON
 */
- (id) JSON;

/**
 * Conforms to NXJSON allowing `NSObjects` to be serialized to JSON
 */
- (id) serialize;

@end
