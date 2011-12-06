//
//  SRHubResult.h
//  SignalR
//
//  Created by Alex Billingsley on 11/2/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SRHubResult : NSObject

@property (nonatomic, strong) id result;
@property (nonatomic, strong) NSString *error;
@property (nonatomic, strong) NSDictionary *state;

- (id)initWithDictionary:(NSDictionary*)dict;
- (void)updateWithDictionary:(NSDictionary *)dict;
- (id) proxyForJson;


@end
