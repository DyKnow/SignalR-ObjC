//
//  SRMockNetwork.h
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 9/2/15.
//  Copyright (c) 2015 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SRMockNetwork : NSObject

+ (id)mockHttpRequestOperationForClass:(Class)aClass
                            statusCode:(NSNumber *)statusCode
                                  json:(id)json;

+ (id)mockHttpRequestOperationForClass:(Class)aClass
                            statusCode:(NSNumber *)statusCode
                                  json:(id)json
                               success:(NSInteger)successIndex
                                 error:(NSInteger)errorIndex;

+ (id)mockHttpRequestOperationForClass:(Class)aClass
                            statusCode:(NSNumber *)statusCode
                        responseString:(NSString *)responseString;


+ (id)mockHttpRequestOperationForClass:(Class)aClass
                            statusCode:(NSNumber *)statusCode
                                 error:(NSError *)error
                               success:(NSInteger)successIndex
                                 error:(NSInteger)errorIndex;

+ (id)mockHttpRequestOperationForClass:(Class)aClass
                            statusCode:(NSNumber *)statusCode
                                 error:(NSError *)error;

+ (id)mockHttpRequestOperationForClass:(Class)aClass
                            statusCode:(NSNumber *)statusCode
                                 error:(NSError *)error
                               success:(NSInteger)successIndex
                                 error:(NSInteger)errorIndex;

@end
