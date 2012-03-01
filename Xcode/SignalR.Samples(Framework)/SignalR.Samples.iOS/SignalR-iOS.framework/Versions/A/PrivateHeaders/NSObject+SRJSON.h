//
//  NSObject+SRJSON.h
//  SignalR.Samples
//
//  Created by Alex Billingsley on 2/21/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark JSON Writing

@interface NSObject (SRJSON)

- (NSString *)SRJSONRepresentation;

@end


#pragma mark JSON Parsing

@interface NSString (SRJSON)

- (id)SRJSONValue;

@end