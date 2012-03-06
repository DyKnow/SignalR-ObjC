//
//  SRHubResult.h
//  SignalR
//
//  Created by Alex Billingsley on 11/2/11.
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
 * An `SRHubResult` object represents a SignalR Server Hub Response
 */
@interface SRHubResult : NSObject

///-------------------------------
/// @name Properties
///-------------------------------

/**
 * A generic result object received from the server
 */
@property (strong, nonatomic, readwrite) id result;

/**
 * An `NSString` represnting an error received from the server
 */
@property (strong, nonatomic, readwrite) NSString *error;

/**
 * An `NSDictionary` represnting a server state object
 */
@property (strong, nonatomic, readwrite) NSDictionary *state;

///-------------------------------
/// @name Initializing an SRHubResult Object
///-------------------------------

/**
 * Initializes a new `SRHubResult` from a `NSDictionary` object deserialized from a JSON server response
 *
 * @param dict a dictionary representing an `SRHubResult`
 */
- (id)initWithDictionary:(NSDictionary*)dict;

///-------------------------------
/// @name Updating an SRHubResult Object
///-------------------------------

/**
 * Updates a new `SRHubResult` from a `NSDictionary` object deserialized from a JSON server response
 *
 * @param dict a dictionary representing an `SRHubResult`
 */
- (void)updateWithDictionary:(NSDictionary *)dict;

///-------------------------------
/// @name JSON Serialization
///-------------------------------

/**
 * Conforms to SBJson (aka json-framework) allowing `SRHubResult` to be serialized to JSON
 */
- (id)proxyForJson;

@end
