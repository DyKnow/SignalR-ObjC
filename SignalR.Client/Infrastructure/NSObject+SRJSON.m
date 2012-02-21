//
//  NSObject+SRJSON.m
//  SignalR.Samples
//
//  Created by Alex Billingsley on 2/21/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import "NSObject+SRJSON.h"

#import "NSObject+SBJson.h"

@implementation NSObject (SRJSON)

- (NSString *)SRJSONRepresentation 
{
    return [self JSONRepresentation];

    NSString *json = nil;
    
    SEL _SBJSONSelector = NSSelectorFromString(@"JSONRepresentation");
    
    if (_SBJSONSelector && [self respondsToSelector:_SBJSONSelector]) 
    {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:_SBJSONSelector]];
        invocation.target = self;
        invocation.selector = _SBJSONSelector;
        
        [invocation invoke];
        [invocation getReturnValue:&json];
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
    return [self JSONValue];

    id JSON = nil;
    
    SEL _SBJSONSelector = NSSelectorFromString(@"JSONValue");
    
    if (_SBJSONSelector && [NSString instancesRespondToSelector:_SBJSONSelector]) 
    {
        // Create a string representation of JSON, to use SBJSON -`JSONValue` category method
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:_SBJSONSelector]];
        invocation.target = self;
        invocation.selector = _SBJSONSelector;
        
        [invocation invoke];
        [invocation getReturnValue:&JSON];
    } 
    else 
    {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Please either target a platform that supports NSJSONSerialization or add one of the following libraries to your project: JSONKit, SBJSON, or YAJL", nil) forKey:NSLocalizedRecoverySuggestionErrorKey];
        [[NSException exceptionWithName:NSInternalInconsistencyException reason:NSLocalizedString(@"No JSON parsing functionality available", nil) userInfo:userInfo] raise];
    }
    
    return JSON;    
}

@end