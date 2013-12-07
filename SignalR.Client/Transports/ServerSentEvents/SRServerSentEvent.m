//
//  SRServerSentEvent.m
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

#import "SRServerSentEvent.h"

@implementation SRServerSentEvent

+ (instancetype)eventWithFields:(NSDictionary *)fields {
    if (!fields) {
        return nil;
    }
    
    SRServerSentEvent *event = [[self alloc] init];
    
    NSMutableDictionary *mutableFields = [NSMutableDictionary dictionaryWithDictionary:fields];
    event.event = mutableFields[@"event"];
    event.identifier = mutableFields[@"id"];
    event.data = [mutableFields[@"data"] dataUsingEncoding:NSUTF8StringEncoding];
    event.retry = [mutableFields[@"retry"] integerValue];
    
    [mutableFields removeObjectsForKeys:@[@"event", @"id", @"data", @"retry"]];
    event.userInfo = mutableFields;
    
    return event;
}

+ (BOOL)tryParseEvent:(NSString *)line sseEvent:(SRServerSentEvent **)sseEvent {
    *sseEvent = nil;
    
    if (line == nil) {
        //TODO: Throw HERE
    }
    
    if([line hasPrefix:@"data:"]) {
        NSString *data = [[line substringFromIndex:@"data:".length] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        *sseEvent = [SRServerSentEvent eventWithFields:@{@"event": @"data", @"data" : data}];
        return YES;
    } else if([line hasPrefix:@"id:"]) {
        NSString *data = [line substringFromIndex:@"id:".length];
        *sseEvent = [SRServerSentEvent eventWithFields:@{@"event": @"id", @"id" : data}];
        return YES;
    }
    
    return NO;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if (!self) {
        return nil;
    }
    
    self.event = [aDecoder decodeObjectForKey:@"event"];
    self.identifier = [aDecoder decodeObjectForKey:@"identifier"];
    self.data = [aDecoder decodeObjectForKey:@"data"];
    self.retry = [aDecoder decodeIntegerForKey:@"retry"];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.event forKey:@"event"];
    [aCoder encodeObject:self.identifier forKey:@"identifier"];
    [aCoder encodeObject:self.data forKey:@"data"];
    [aCoder encodeInteger:self.retry forKey:@"retry"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    SRServerSentEvent *event = [[[self class] allocWithZone:zone] init];
    event.event = self.event;
    event.identifier = self.identifier;
    event.data = self.data;
    event.retry = self.retry;
    
    return event;
}

@end
