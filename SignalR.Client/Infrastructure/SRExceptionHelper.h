//
//  SRExceptionHelper.h
//  SignalR.Samples
//
//  Created by Alex Billingsley on 6/8/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SRExceptionHelper : NSObject

/**
 * Performs a check to see if the underlying HTTP request was cancelled
 *
 * @param error an error returned from the underlying HTTP request `SRHttpHelper`
 * @return YES if the request was aborted, NO if not
 */
+ (BOOL)isRequestAborted:(NSError *)error;

@end
