//
//  SRMockNetwork.m
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 9/2/15.
//  Copyright (c) 2015 DyKnow LLC. All rights reserved.
//

#import "SRMockNetwork.h"
#import <OCMock/OCMock.h>
#import <AFNetworking/AFNetworking.h>

@implementation SRMockNetwork

+ (id)stub:(id)mock
statusCode:(NSNumber *)statusCode
      json:(id)json
   success:(NSInteger)successIndex
     error:(NSInteger)errorIndex {
    [[[mock stub] andDo:^(NSInvocation *invocation) {
        if ([statusCode  isEqual: @200]) {
            void (^successBlock)(AFHTTPRequestOperation *operation, id responseObject) = nil;
            [invocation getArgument:&successBlock atIndex:2];
            if (successBlock) {
                if ([json isKindOfClass:[NSString class]]) {
                    [[[mock stub] andReturn:[json dataUsingEncoding:NSUTF8StringEncoding]] responseData];
                    [[[mock stub] andReturn:json] responseString];
                } else if ([json isKindOfClass:[NSDictionary class]] ||
                           [json isKindOfClass:[NSSet class]] ||
                           [json isKindOfClass:[NSArray class]]) {
                    NSData *responseData = [NSJSONSerialization dataWithJSONObject:json options:(NSJSONWritingOptions)0 error:NULL];
                    NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                    [[[mock stub] andReturn:responseData] responseData];
                    [[[mock stub] andReturn:responseString] responseString];
                }
                
                successBlock(mock, json);
            }
        } else {
            void (^errorBlock)(AFHTTPRequestOperation *operation, NSError *error) = nil;
            [invocation getArgument:&errorBlock atIndex:3];
            if (errorBlock) {
                errorBlock(mock, json);
            }
        }
    }] setCompletionBlockWithSuccess:[OCMArg any] failure:[OCMArg any]];
    return mock;
}

+ (id)mockHttpRequestOperationForClass:(Class)aClass
                            statusCode:(NSNumber *)statusCode
                                  json:(id)json {
    return [[self class] mockHttpRequestOperationForClass:aClass statusCode:statusCode json:json success:2 error:3];
}


+ (id)mockHttpRequestOperationForClass:(Class)aClass
                            statusCode:(NSNumber *)statusCode
                                  json:(id)json
                               success:(NSInteger)successIndex
                                 error:(NSInteger)errorIndex {
    id operationMock = [OCMockObject niceMockForClass:[AFHTTPRequestOperation class]];
    [[[operationMock stub] andReturn:operationMock] alloc];
    // And we stub initWithParam: passing the param we will pass to the method to test
    [[[operationMock stub] andReturn:operationMock] initWithRequest:[OCMArg any]];
    return [[self class] stub:operationMock statusCode:statusCode json:json success:successIndex error:errorIndex];
}

+ (id)mockHttpRequestOperationForClass:(Class)aClass
                            statusCode:(NSNumber *)statusCode
                        responseString:(NSString *)responseString; {
    return [[self class] mockHttpRequestOperationForClass:aClass statusCode:statusCode json:responseString];
}

+ (id)mockHttpRequestOperationForClass:(Class)aClass
                            statusCode:(NSNumber *)statusCode
                        responseString:(NSString *)responseString
                               success:(NSInteger)successIndex
                                 error:(NSInteger)errorIndex; {
    return [[self class] mockHttpRequestOperationForClass:aClass statusCode:statusCode json:responseString success:successIndex error:errorIndex];
}

+ (id)mockHttpRequestOperationForClass:(Class)aClass
                            statusCode:(NSNumber *)statusCode
                                 error:(NSError *)error; {
    return [[self class] mockHttpRequestOperationForClass:aClass statusCode:statusCode json:error];
}

+ (id)mockHttpRequestOperationForClass:(Class)aClass
                            statusCode:(NSNumber *)statusCode
                                 error:(NSError *)error
                               success:(NSInteger)successIndex
                                 error:(NSInteger)errorIndex; {
    return [[self class] mockHttpRequestOperationForClass:aClass statusCode:statusCode json:error success:successIndex error:errorIndex];
}

@end
