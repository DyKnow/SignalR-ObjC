//
//  NSObject+SRJSON.m
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

#import "NSObject+SRJSON.h"

@implementation NSObject (SRJSON)

- (id)ensureFoundationObject:(id)object {
    if ([object isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *validJSONDictionary = [NSMutableDictionary dictionary];
        
        for (id _key in object) {
            if ([_key isKindOfClass:[NSString class]]) {
                id jsonObject = [self ensureFoundationObject:object[_key]];
                validJSONDictionary[_key] = jsonObject;
            } else {
                return nil;
            }
        }
        return validJSONDictionary;
    } else if ([object isKindOfClass:[NSSet class]]) {
        return [object allObjects];
    } else if ([object isKindOfClass:[NSArray class]]) {
        NSMutableArray *validJSONArray = [NSMutableArray array];
        
        for (id _object in object) {
            id jsonObject = [self ensureFoundationObject:_object];
            [validJSONArray addObject:jsonObject];
        }
        return validJSONArray;
    } else if([object isKindOfClass:[NSString class]] ||
              [object isKindOfClass:[NSNumber class]] ||
              [object isKindOfClass:[NSNull class]]) {
        return object;
    } else {
        SEL _YAJLSelector = NSSelectorFromString(@"JSON");
        SEL _SBJSONSelector = NSSelectorFromString(@"proxyForJson");
        SEL _NXJsonSelector = NSSelectorFromString(@"serialize");
        
        if (_SBJSONSelector && [object respondsToSelector:_SBJSONSelector]) {
            NSObject *json;
            __unsafe_unretained NSObject *jsonTemp = nil;
            
            NSMethodSignature *signature = [object methodSignatureForSelector:_SBJSONSelector];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setTarget:object];
            [invocation setSelector:_SBJSONSelector];
            
            [invocation invoke];
            [invocation getReturnValue:&jsonTemp];
            
            json = jsonTemp;
            
            if(json == nil) goto throw;
            
            return [self ensureFoundationObject:json];
        } else if (_YAJLSelector && [object respondsToSelector:_YAJLSelector]) {
            NSObject *json;
            __unsafe_unretained NSObject *jsonTemp = nil;
            
            NSMethodSignature *signature = [object methodSignatureForSelector:_YAJLSelector];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setTarget:object];
            [invocation setSelector:_YAJLSelector];
            
            [invocation invoke];
            [invocation getReturnValue:&jsonTemp];
            
            json = jsonTemp;
            
            if(json == nil) goto throw;
            
            return [self ensureFoundationObject:json];
        } else if (_NXJsonSelector && [object respondsToSelector:_NXJsonSelector]) { 
            NSObject *json;
            __unsafe_unretained NSObject *jsonTemp = nil;
            
            NSMethodSignature *signature = [object methodSignatureForSelector:_NXJsonSelector];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setTarget:object];
            [invocation setSelector:_NXJsonSelector];
            
            [invocation invoke];
            [invocation getReturnValue:&jsonTemp];
            
            json = jsonTemp;
            
            if(json == nil) goto throw;
            
            return [self ensureFoundationObject:json];
        }
    }

throw:;
    NSDictionary *userInfo = @{NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Your NSObject subclass should implement at least one of the following: proxyForJson; JSON; or serialize; as defined in SRSerializable.h", nil)};
    [[NSException exceptionWithName:NSInternalInconsistencyException reason:NSLocalizedString(@"Invalid JSON Object", nil) userInfo:userInfo] raise];

    return nil;
}

- (NSString *)SRJSONRepresentation  {
    id object = [self ensureFoundationObject:self];
    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:(NSJSONWritingOptions)0 error:NULL];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end


@implementation NSString (SRJSON)

- (id)SRJSONValue {
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    return [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)0 error:NULL];
}

@end