//
//  SRHubRegistrationData.h
//  SignalR
//
//  Created by Alex Billingsley on 11/2/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SRHubRegistrationData : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSMutableArray *methods;

- (id)initWithDictionary:(NSDictionary*)dict;
- (void)updateWithDictionary:(NSDictionary *)dict;
- (id) proxyForJson;

@end
