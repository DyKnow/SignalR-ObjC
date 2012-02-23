//
//  NSObject+SRJSON.m
//  SignalR.Samples
//
//  Created by Alex Billingsley on 2/21/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import "NSObject+SRJSON.h"

@implementation NSObject (SRJSON)

- (id)ensureFoundationObject:(id)object 
{
    if ([object isKindOfClass:[NSDictionary class]])
    {
        NSMutableDictionary *validJSONDictionary = [NSMutableDictionary dictionary];
        
        for (id _key in object)
        {
            if ([_key isKindOfClass:[NSString class]])
            {
                id jsonObject = [self ensureFoundationObject:[object objectForKey:_key]];
                [validJSONDictionary setObject:jsonObject forKey:_key];
            }
            else
            {
                return nil;
            }
        }
        return validJSONDictionary;
    }
    else if ([object isKindOfClass:[NSArray class]])
    {
        NSMutableArray *validJSONArray = [NSMutableArray array];
        
        for (id _object in object)
        {
            id jsonObject = [self ensureFoundationObject:_object];
            [validJSONArray addObject:jsonObject];
        }
        return validJSONArray;
    }
    else if([object isKindOfClass:[NSString class]] ||
            [object isKindOfClass:[NSNumber class]] ||
            [object isKindOfClass:[NSNull class]])
    {
        return object;
    }
    else 
    {
        SEL _YAJLSelector = NSSelectorFromString(@"JSON");
        SEL _SBJSONSelector = NSSelectorFromString(@"proxyForJson");
        
        if (_SBJSONSelector && [object respondsToSelector:_SBJSONSelector]) 
        {
            NSObject *json;
            __unsafe_unretained NSObject *jsonTemp = nil;
            
            NSMethodSignature *signature = [object methodSignatureForSelector:_SBJSONSelector];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setTarget:object];
            [invocation setSelector:_SBJSONSelector];
            
            [invocation invoke];
            [invocation getReturnValue:&jsonTemp];
            
            json = jsonTemp;
            
            return [self ensureFoundationObject:json];
        }
        else if (_YAJLSelector && [object respondsToSelector:_YAJLSelector]) 
        { 
            NSObject *json;
            __unsafe_unretained NSObject *jsonTemp = nil;
            
            NSMethodSignature *signature = [object methodSignatureForSelector:_YAJLSelector];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setTarget:object];
            [invocation setSelector:_YAJLSelector];
            
            [invocation invoke];
            [invocation getReturnValue:&jsonTemp];
            
            json = jsonTemp;
            
            return [self ensureFoundationObject:json];
        }
    }
    return nil;
}

- (NSString *)SRJSONRepresentation 
{
    NSString *json;
    __unsafe_unretained NSString *jsonTemp = nil;  

    id jsonObject = [self ensureFoundationObject:self];
    
    SEL _JSONKitSelector = NSSelectorFromString(@"JSONString"); 
    SEL _SBJSONSelector = NSSelectorFromString(@"JSONRepresentation");
    SEL _YAJLSelector = NSSelectorFromString(@"yajl_JSONString");
    
    id _NSJSONSerializationClass = NSClassFromString(@"NSJSONSerialization");
    SEL _NSJSONSerializationSelector = NSSelectorFromString(@"dataWithJSONObject:options:error:");
    
    if (_JSONKitSelector && [jsonObject respondsToSelector:_JSONKitSelector]) 
    {
        NSMethodSignature *signature = [jsonObject methodSignatureForSelector:_JSONKitSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:jsonObject];
        [invocation setSelector:_JSONKitSelector];
        
        [invocation invoke];
        [invocation getReturnValue:&jsonTemp];
        
        json = jsonTemp;
    }
    else if (_SBJSONSelector && [jsonObject respondsToSelector:_SBJSONSelector]) 
    {
        NSMethodSignature *signature = [jsonObject methodSignatureForSelector:_SBJSONSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:jsonObject];
        [invocation setSelector:_SBJSONSelector];
        
        [invocation invoke];
        [invocation getReturnValue:&jsonTemp]; 
        
        json = jsonTemp;
    } 
    else if (_YAJLSelector && [jsonObject respondsToSelector:_YAJLSelector]) 
    {
        NSMethodSignature *signature = [jsonObject methodSignatureForSelector:_YAJLSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:jsonObject];
        [invocation setSelector:_YAJLSelector];
        
        [invocation invoke];
        [invocation getReturnValue:&jsonTemp];
        
        json = jsonTemp;
    } 
    else if (_NSJSONSerializationClass && [_NSJSONSerializationClass respondsToSelector:_NSJSONSerializationSelector]) 
    {
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
    }
    else 
    {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Please either target a platform that supports NSJSONSerialization or add one of the following libraries to your project: JSONKit, SBJSON, or YAJL", nil) forKey:NSLocalizedRecoverySuggestionErrorKey];
        [[NSException exceptionWithName:NSInternalInconsistencyException reason:NSLocalizedString(@"No JSON generation functionality available", nil) userInfo:userInfo] raise];
    }
    
    return json;
}

@end


@implementation NSString (SRJSON)

- (id)SRJSONValue 
{
    NSObject *json;
    __unsafe_unretained NSObject *jsonTemp = nil;
    
    SEL _JSONKitSelector = NSSelectorFromString(@"objectFromJSONString"); 
    SEL _SBJSONSelector = NSSelectorFromString(@"JSONValue");
    SEL _YAJLSelector = NSSelectorFromString(@"yajl_JSON");
    
    id _NSJSONSerializationClass = NSClassFromString(@"NSJSONSerialization");
    SEL _NSJSONSerializationSelector = NSSelectorFromString(@"JSONObjectWithData:options:error:");

    if (_JSONKitSelector && [self respondsToSelector:_JSONKitSelector]) 
    {
        NSMethodSignature *signature = [self methodSignatureForSelector:_JSONKitSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:self];
        [invocation setSelector:_JSONKitSelector];
        
        [invocation invoke];
        [invocation getReturnValue:&jsonTemp];
        
        json = jsonTemp;
    }
    else if (_SBJSONSelector &&  [self respondsToSelector:_SBJSONSelector])
    {
        NSMethodSignature *signature = [self methodSignatureForSelector:_SBJSONSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:self];
        [invocation setSelector:_SBJSONSelector];
        
        [invocation invoke];
        [invocation getReturnValue:&jsonTemp]; 
        
        json = jsonTemp;
    } 
    else if (_YAJLSelector && [self respondsToSelector:_YAJLSelector]) 
    {
        NSMethodSignature *signature = [self methodSignatureForSelector:_YAJLSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:self];
        [invocation setSelector:_YAJLSelector];

        [invocation invoke];
        [invocation getReturnValue:&jsonTemp];
        
        json = jsonTemp;
    }
    else if (_NSJSONSerializationClass && [_NSJSONSerializationClass respondsToSelector:_NSJSONSerializationSelector]) 
    {
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
    }
    else 
    {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Please either target a platform that supports NSJSONSerialization or add one of the following libraries to your project: JSONKit, SBJSON, or YAJL", nil) forKey:NSLocalizedRecoverySuggestionErrorKey];
        [[NSException exceptionWithName:NSInternalInconsistencyException reason:NSLocalizedString(@"No JSON generation functionality available", nil) userInfo:userInfo] raise];
    }
    
    return json;
}

@end