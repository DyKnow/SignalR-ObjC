//
//  SRSubscription.h
//  SignalR
//
//  Created by Alex Billingsley on 11/2/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SRSubscription : NSObject

@property (nonatomic, strong) NSObject *object;
@property (nonatomic, assign) SEL selector;

@end
