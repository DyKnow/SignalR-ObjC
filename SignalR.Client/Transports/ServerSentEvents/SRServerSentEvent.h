//
//  SRServerSentEvent.h
//  SignalR
//
//  Created by Alex Billingsley on 6/8/12.
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
    Copied from AFRocketClient, When AFRocket is more stable it will probably make sense to replace our SSE implementation with theirs.
 */
@interface SRServerSentEvent : NSObject <NSCoding, NSCopying>

///---------------------------------
/// @name Managing Event Information
///---------------------------------

/**
 The event type.
 */
@property (nonatomic, copy) NSString *event;

/**
 The event identifier.
 */
@property (nonatomic, copy) NSString *identifier;

/**
 The data associated with the event.
 */
@property (nonatomic, strong) NSData *data;

/**
 The retry interval sent with the event.
 */
@property (nonatomic, assign) NSTimeInterval retry;

/**
 Any additional fields in the event.
 */
@property (nonatomic, strong) NSDictionary *userInfo;

///------------------------
/// @name Creating an Event
///------------------------

/**
 Creates and returns an event with the specified fields.
 */
+ (instancetype)eventWithFields:(NSDictionary *)fields;

+ (BOOL)tryParseEvent:(NSString *)line sseEvent:(SRServerSentEvent **)sseEvent;
@end