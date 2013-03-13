//
//  SRVersion.h
//  SignalR
//
//  Created by Alex Billingsley on 1/10/12.
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
 * `SRVersion` represents the signalr protocol version number.
 */
@interface SRVersion : NSObject

///-------------------------------
/// @name Properties
///-------------------------------

/**
 * The value of the build component of the version number for the current `SRVersion` object.
 */
@property (assign, nonatomic, readwrite) NSInteger build;

/**
 * The value of the major component of the version number for the current `SRVersion` object.
 */
@property (assign, nonatomic, readwrite) NSInteger major;

/**
 * The value of the majorRevision component of the version number for the current `SRVersion` object.
 */
@property (assign, nonatomic, readwrite) NSInteger majorRevision;

/**
 * The value of the minor component of the version number for the current `SRVersion` object.
 */
@property (assign, nonatomic, readwrite) NSInteger minor;

/**
 * The value of the minorRevision component of the version number for the current `SRVersion` object.
 */
@property (assign, nonatomic, readwrite) NSInteger minorRevision;

/**
 * The value of the revision component of the version number for the current `SRVersion` object.
 */
@property (assign, nonatomic, readwrite) NSInteger revision;

///-------------------------------
/// @name Initializing an SRVersion Object
///-------------------------------

/**
 * Initializes a new instance of the `SRVersion` class using the specified major and minor values.
 *
 * @param major an `NSInteger` representing the major component of a version
 * @param minor an `NSInteger` representing the minior component of a version
 */
- (instancetype)initWithMajor:(NSInteger)major minor:(NSInteger)minor;

/**
 * Initializes a new instance of the `SRVersion` class using the specified major, minor, and build values.
 *
 * @param major an `NSInteger` representing the major component of a version
 * @param minor an `NSInteger` representing the minior component of a version
 * @param build an `NSInteger` representing the build component of a version
 */
- (instancetype)initWithMajor:(NSInteger)major minor:(NSInteger)minor build:(NSInteger)build;

/**
 * Initializes a new instance of the `SRVersion` class using the specified major, minor, build and revision values.
 *
 * @param major an `NSInteger` representing the major component of a version
 * @param minor an `NSInteger` representing the minior component of a version
 * @param build an `NSInteger` representing the build component of a version
 * @param revision an `NSInteger` representing the revision component of a version
 */
- (instancetype)initWithMajor:(NSInteger)major minor:(NSInteger)minor build:(NSInteger)build revision:(NSInteger)revision;

/**
 * Tries to convert the string representation of a version number to an equivalent `SRVersion` object, and returns a value that indicates whether the conversion succeeded.
 *
 * @param input an `NSString` representing an `SRVersion` to convert
 * @param version the parsed `SRVersion` object
 *
 * @return a bool representing the sucess of the parse
 */
+ (BOOL)tryParse:(NSString *)input forVersion:(SRVersion **)version;

@end
