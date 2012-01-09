//
//  SRHttpHelper.h
//  SignalR
//
//  Created by Alex Billingsley on 10/18/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "DKHttpHelper.h"

@interface SRHttpHelper : DKHttpHelper

@property (strong, nonatomic, readonly) NSOperationQueue *queue;

@end
