//
//  SRHubClientInvocation.h
//  SignalR
//
//  Created by Alex Billingsley on 11/7/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SRHubClientInvocation : NSObject

@property (nonatomic, strong) NSString *hub;
@property (nonatomic, strong) NSString *method;
@property (nonatomic, strong) NSMutableArray *args;
@property (nonatomic, strong) NSMutableDictionary *state;

- (id)initWithDictionary:(NSDictionary*)dict;
- (void)updateWithDictionary:(NSDictionary *)dict;
- (id) proxyForJson;

@end
