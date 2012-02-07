//
//  SRHubRegistrationData.h
//  SignalR
//
//  Created by Alex Billingsley on 11/2/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SRHubRegistrationData : NSObject

@property (strong, nonatomic, readwrite) NSString *name;
@property (strong, nonatomic, readwrite) NSMutableArray *methods;

- (id)initWithDictionary:(NSDictionary*)dict;
- (void)updateWithDictionary:(NSDictionary *)dict;
- (id)proxyForJson;

@end
