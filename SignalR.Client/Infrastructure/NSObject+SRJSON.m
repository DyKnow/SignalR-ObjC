//
//  NSObject+SRJSON.m
//  SignalR.Samples
//
//  Created by Alex Billingsley on 2/21/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import "NSObject+SRJSON.h"

//TODO: Add to mac project, test, make arc compatibile if possible
@implementation NSObject (SRJSON)

- (id)ensureFoundationObject:(id)object 
{
    if(![NSJSONSerialization isValidJSONObject:object])
    {
        SEL _YAJLSelector = NSSelectorFromString(@"JSON");
        SEL _SBJSONSelector = NSSelectorFromString(@"proxyForJson");
        
        if (_SBJSONSelector && [object respondsToSelector:_SBJSONSelector]) 
        {
            id jsonObject;
            NSMethodSignature *signature = [object methodSignatureForSelector:_SBJSONSelector];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setTarget:object];
            [invocation setSelector:_SBJSONSelector];
            
            [invocation invoke];
            [invocation getReturnValue:&jsonObject];
            
            return [self ensureFoundationObject:jsonObject];
        }
        else if (_YAJLSelector && [object respondsToSelector:_YAJLSelector]) 
        { 
            id jsonObject;
            NSMethodSignature *signature = [object methodSignatureForSelector:_YAJLSelector];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setTarget:object];
            [invocation setSelector:_YAJLSelector];
            
            [invocation invoke];
            [invocation getReturnValue:&jsonObject];
            
            return [self ensureFoundationObject:jsonObject];
        }
    }
    
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
    
    return nil;
}

- (NSString *)SRJSONRepresentation 
{
    NSString *json = nil;
    
    SEL _SBJSONSelector = NSSelectorFromString(@"JSONRepresentation");
    SEL _YAJLSelector = NSSelectorFromString(@"yajl_JSONString");
    
    id _NSJSONSerializationClass = NSClassFromString(@"NSJSONSerialization");
    SEL _NSJSONSerializationSelector = NSSelectorFromString(@"dataWithJSONObject:options:error:");
        
    if (_NSJSONSerializationClass && [_NSJSONSerializationClass respondsToSelector:_NSJSONSerializationSelector]) 
    {
        NSUInteger writeOptions = 0;
        NSError *error;
        id jsonObject = [self ensureFoundationObject:self];
        
        NSMethodSignature *signature = [_NSJSONSerializationClass methodSignatureForSelector:_NSJSONSerializationSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:_NSJSONSerializationClass];
        [invocation setSelector:_NSJSONSerializationSelector];
        
        [invocation setArgument:&jsonObject atIndex:2]; // arguments 0 and 1 are self and _cmd respectively, automatically set by NSInvocation
        [invocation setArgument:&writeOptions atIndex:3];
        [invocation setArgument:&error atIndex:4];
        
        [invocation invoke];
        [invocation getReturnValue:&json];
    }
    if (_SBJSONSelector && [self respondsToSelector:_SBJSONSelector]) 
    {
        NSMethodSignature *signature = [self methodSignatureForSelector:_SBJSONSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:self];
        [invocation setSelector:_SBJSONSelector];
        
        [invocation invoke];
        [invocation getReturnValue:&json];     
    } 
    else if (_YAJLSelector && [self respondsToSelector:_YAJLSelector]) 
    {
        NSMethodSignature *signature = [self methodSignatureForSelector:_YAJLSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:self];
        [invocation setSelector:_YAJLSelector];
        
        [invocation invoke];
        [invocation getReturnValue:&json];
    } 
    //TODO: support JSONKit
    else 
    {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Please add one of the following libraries to your project: SBJSON or YAJL", nil) forKey:NSLocalizedRecoverySuggestionErrorKey];
        [[NSException exceptionWithName:NSInternalInconsistencyException reason:NSLocalizedString(@"No JSON generation functionality available", nil) userInfo:userInfo] raise];
    }
    
    return json;
}

@end


@implementation NSString (SRJSON)

- (id)SRJSONValue 
{
    id json = nil;
    
    SEL _SBJSONSelector = NSSelectorFromString(@"JSONValue");
    SEL _YAJLSelector = NSSelectorFromString(@"yajl_JSON");
    
    id _NSJSONSerializationClass = NSClassFromString(@"NSJSONSerialization");
    SEL _NSJSONSerializationSelector = NSSelectorFromString(@"JSONObjectWithData:options:error:");

    if (_NSJSONSerializationClass && [_NSJSONSerializationClass respondsToSelector:_NSJSONSerializationSelector]) 
    {
        NSUInteger readOptions = 0;
        NSError *error;
        NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
        
        NSMethodSignature *signature = [_NSJSONSerializationClass methodSignatureForSelector:_NSJSONSerializationSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:_NSJSONSerializationClass];
        [invocation setSelector:_NSJSONSerializationSelector];

        [invocation setArgument:&data atIndex:2];
        [invocation setArgument:&readOptions atIndex:3];
        [invocation setArgument:&error atIndex:4];
        
        [invocation invoke];
        [invocation getReturnValue:&json];
    }
    else if (_SBJSONSelector &&  [self respondsToSelector:_SBJSONSelector])
    {
        NSMethodSignature *signature = [self methodSignatureForSelector:_SBJSONSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:self];
        [invocation setSelector:_SBJSONSelector];
        
        [invocation invoke];
        [invocation getReturnValue:&json]; 
    } 
    else if (_YAJLSelector && [self respondsToSelector:_YAJLSelector]) 
    {
        NSMethodSignature *signature = [self methodSignatureForSelector:_YAJLSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:self];
        [invocation setSelector:_YAJLSelector];

        [invocation invoke];
        [invocation getReturnValue:&json];
    }
    //TODO: support JSONKit
    else 
    {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Please add one of the following libraries to your project: SBJSON or YAJL", nil) forKey:NSLocalizedRecoverySuggestionErrorKey];
        [[NSException exceptionWithName:NSInternalInconsistencyException reason:NSLocalizedString(@"No JSON generation functionality available", nil) userInfo:userInfo] raise];
    }
    
    return json;
}

@end