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

@synthesize string = _string;
@synthesize stream = _stream;
@synthesize error = _error;

@synthesize response = _response;

- (id)initWithResponse:(id)response
{
    static NSString *empty = @"";
    
    if (self = [super init])
    {
        if([response isKindOfClass:[NSError class]])
        {
            _error = response;
        }
        else if([response isKindOfClass:[NSOutputStream class]])
        {
            _stream = response;
        }
        else if([response isKindOfClass:[NSString class]])
        {
            _string = response;
        }
        else
        {
            _string = empty;
        }
    }
    return self;
}

@end
