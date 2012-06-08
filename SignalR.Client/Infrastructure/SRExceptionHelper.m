//
//  SRExceptionHelper.m
//  SignalR.Samples
//
//  Created by Alex Billingsley on 6/8/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import "SRExceptionHelper.h"

@implementation SRExceptionHelper

+ (BOOL)isRequestAborted:(NSError *)error
{
    return (error != nil && (error.code == NSURLErrorCancelled));
}

@end
