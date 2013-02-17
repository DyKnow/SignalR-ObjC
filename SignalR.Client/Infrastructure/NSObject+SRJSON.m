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
    NSString *json;
    __unsafe_unretained NSString *jsonTemp = nil;  

    id jsonObject = [self ensureFoundationObject:self];
    
    SEL _JSONKitSelector = NSSelectorFromString(@"JSONString"); 
    SEL _SBJSONSelector = NSSelectorFromString(@"JSONRepresentation");
    SEL _YAJLSelector = NSSelectorFromString(@"yajl_JSONString");
    
    id _NXJsonSerializerClass = NSClassFromString(@"NXJsonSerializer");
    SEL _NXJsonSerializerSelector = NSSelectorFromString(@"serialize:");

    id _NSJSONSerializationClass = NSClassFromString(@"NSJSONSerialization");
    SEL _NSJSONSerializationSelector = NSSelectorFromString(@"dataWithJSONObject:options:error:");
    
    if (_JSONKitSelector && [jsonObject respondsToSelector:_JSONKitSelector]) {
        NSMethodSignature *signature = [jsonObject methodSignatureForSelector:_JSONKitSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:jsonObject];
        [invocation setSelector:_JSONKitSelector];
        
        [invocation invoke];
        [invocation getReturnValue:&jsonTemp];
        
        json = jsonTemp;
    } else if (_SBJSONSelector && [jsonObject respondsToSelector:_SBJSONSelector]) {
        NSMethodSignature *signature = [jsonObject methodSignatureForSelector:_SBJSONSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:jsonObject];
        [invocation setSelector:_SBJSONSelector];
        
        [invocation invoke];
        [invocation getReturnValue:&jsonTemp]; 
        
        json = jsonTemp;
    } else if (_YAJLSelector && [jsonObject respondsToSelector:_YAJLSelector]) {
        NSMethodSignature *signature = [jsonObject methodSignatureForSelector:_YAJLSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:jsonObject];
        [invocation setSelector:_YAJLSelector];
        
        [invocation invoke];
        [invocation getReturnValue:&jsonTemp];
        
        json = jsonTemp;
    } else if (_NXJsonSerializerClass && [_NXJsonSerializerClass respondsToSelector:_NXJsonSerializerSelector]) {
        __unsafe_unretained NSString *jsonString = jsonObject;
        
        NSMethodSignature *signature = [_NXJsonSerializerClass methodSignatureForSelector:_NXJsonSerializerSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:_NXJsonSerializerClass];
        [invocation setSelector:_NXJsonSerializerSelector];
        
        [invocation setArgument:&jsonString atIndex:2];
        
        [invocation invoke];
        [invocation getReturnValue:&jsonTemp];
        
        json = jsonTemp;
    } else if (_NSJSONSerializationClass && [_NSJSONSerializationClass respondsToSelector:_NSJSONSerializationSelector]) {
        __unsafe_unretained NSString *jsonString = jsonObject;
        __unsafe_unretained NSData *JSONData = nil;

        NSUInteger writeOptions = 0;
        __unsafe_unretained NSError *error;
        
        NSMethodSignature *signature = [_NSJSONSerializationClass methodSignatureForSelector:_NSJSONSerializationSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:_NSJSONSerializationClass];
        [invocation setSelector:_NSJSONSerializationSelector];
        
        [invocation setArgument:&jsonString atIndex:2];
        [invocation setArgument:&writeOptions atIndex:3];
        [invocation setArgument:&error atIndex:4];
        
        [invocation invoke];
        [invocation getReturnValue:&JSONData];

        json = [[NSString alloc] initWithData:JSONData encoding:NSUTF8StringEncoding];
    } else {
        NSDictionary *userInfo = @{NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Please either target a platform that supports NSJSONSerialization or add one of the following libraries to your project: JSONKit, SBJSON, or YAJL", nil)};
        [[NSException exceptionWithName:NSInternalInconsistencyException reason:NSLocalizedString(@"No JSON generation functionality available", nil) userInfo:userInfo] raise];
    }
    
    return json;
}

@end


@implementation NSString (SRJSON)

- (id)SRJSONValue {
    NSObject *json;
    __unsafe_unretained NSObject *jsonTemp = nil;
    
    SEL _JSONKitSelector = NSSelectorFromString(@"objectFromJSONString"); 
    SEL _SBJSONSelector = NSSelectorFromString(@"JSONValue");
    SEL _YAJLSelector = NSSelectorFromString(@"yajl_JSON");
    
    id _NXJsonParserClass = NSClassFromString(@"NXJsonParser");
    SEL _NXJsonParserSelector = NSSelectorFromString(@"parseData:error:ignoreNulls:");

    id _NSJSONSerializationClass = NSClassFromString(@"NSJSONSerialization");
    SEL _NSJSONSerializationSelector = NSSelectorFromString(@"JSONObjectWithData:options:error:");

    if (_JSONKitSelector && [self respondsToSelector:_JSONKitSelector]) {
        NSMethodSignature *signature = [self methodSignatureForSelector:_JSONKitSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:self];
        [invocation setSelector:_JSONKitSelector];
        
        [invocation invoke];
        [invocation getReturnValue:&jsonTemp];
        
        json = jsonTemp;
    } else if (_SBJSONSelector &&  [self respondsToSelector:_SBJSONSelector]) {
        NSMethodSignature *signature = [self methodSignatureForSelector:_SBJSONSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:self];
        [invocation setSelector:_SBJSONSelector];
        
        [invocation invoke];
        [invocation getReturnValue:&jsonTemp]; 
        
        json = jsonTemp;
    } else if (_YAJLSelector && [self respondsToSelector:_YAJLSelector]) {
        NSMethodSignature *signature = [self methodSignatureForSelector:_YAJLSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:self];
        [invocation setSelector:_YAJLSelector];

        [invocation invoke];
        [invocation getReturnValue:&jsonTemp];
        
        json = jsonTemp;
    } else if (_NXJsonParserClass && [_NXJsonParserClass respondsToSelector:_NXJsonParserSelector]) {
        __unsafe_unretained NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
        __unsafe_unretained NSError *error;
        
        NSNumber *nullOption = @YES;
        NSMethodSignature *signature = [_NXJsonParserClass methodSignatureForSelector:_NXJsonParserSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:_NXJsonParserClass];
        [invocation setSelector:_NXJsonParserSelector];
        
        [invocation setArgument:&data atIndex:2];
        [invocation setArgument:&error atIndex:3];
        [invocation setArgument:&nullOption atIndex:4];
        
        [invocation invoke];
        [invocation getReturnValue:&jsonTemp];
        
        json = jsonTemp;
    } else if (_NSJSONSerializationClass && [_NSJSONSerializationClass respondsToSelector:_NSJSONSerializationSelector]) {
        __unsafe_unretained NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];

        NSUInteger readOptions = 0;
        __unsafe_unretained NSError *error;
        
        NSMethodSignature *signature = [_NSJSONSerializationClass methodSignatureForSelector:_NSJSONSerializationSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:_NSJSONSerializationClass];
        [invocation setSelector:_NSJSONSerializationSelector];
        
        [invocation setArgument:&data atIndex:2];
        [invocation setArgument:&readOptions atIndex:3];
        [invocation setArgument:&error atIndex:4];
        
        [invocation invoke];
        [invocation getReturnValue:&jsonTemp];
        
        json = jsonTemp;
    } else {
        NSDictionary *userInfo = @{NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Please either target a platform that supports NSJSONSerialization or add one of the following libraries to your project: JSONKit, SBJSON, or YAJL", nil)};
        [[NSException exceptionWithName:NSInternalInconsistencyException reason:NSLocalizedString(@"No JSON generation functionality available", nil) userInfo:userInfo] raise];
    }
    
    return json;
}

@end