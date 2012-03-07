//
//  NSObject+SRJSON.h
//  SignalR
//
//  Created by Alex Billingsley on 10/18/11.
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

#pragma mark JSON Writing

/**
 * A category on `NSObject` which adds JSON generation to `NSObject`
 */
@interface NSObject (SRJSON)

/**
 * Encodes the receiver into a JSON string
 * @return the receiver encoded in JSON, or nil on error.
 */
- (NSString *)SRJSONRepresentation;

@end


#pragma mark JSON Parsing

/**
 * A category on `NSString` which adds JSON parsing methods to `NSString`
 */
@interface NSString (SRJSON)

/**
 * Decodes the receiver's JSON text
 *
 * the NSDictionary` or `NSArray` represented by the receiver, or nil on error.
 */
- (id)SRJSONValue;

@end