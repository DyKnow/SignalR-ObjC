//
//  SRDefaultHttpWebResponseWrapper.m
//  SignalR.Samples
//
//  Created by Alex Billingsley on 6/8/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import "SRDefaultHttpWebResponseWrapper.h"

@interface SRDefaultHttpWebResponseWrapper ()

@property (strong, nonatomic, readwrite) id response;

@end

@implementation SRDefaultHttpWebResponseWrapper

@synthesize response = _response;

- (id)initWithResponse:(id)response
{
    if (self = [super init])
    {
        _response = response;
    }
    return self;
}

@end
