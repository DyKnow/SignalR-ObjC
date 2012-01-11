//
//  SRVersion.m
//  SignalR
//
//  Created by Alex Billingsley on 1/10/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import "SRVersion.h"

@interface SRVersion ()

@end

@implementation SRVersion

@synthesize build = _build;
@synthesize major = _major;
@synthesize majorRevision = _majorRevision;
@synthesize minor = _minor;
@synthesize minorRevision = _minorRevision;
@synthesize revision = _revision;

- (id)init
{
    if(self = [super init])
    {
        _build = 0;
        _major = 0;
        _majorRevision = 0;
        _minor = 0;
        _minorRevision = 0;
        _revision = 0;
    }
    return self;
}

- (id)initWithMajor:(NSInteger)major minor:(NSInteger)minor
{
    if(self = [self init])
    {
        _major = major;
        _minor = minor;
        
        if(_major < 0 || _minor < 0)
        {
            [NSException raise:@"ArgumentOutOfRangeException" format:@"Component cannot be less than 0"];
        }
    }
    return self;
}

- (id)initWithMajor:(NSInteger)major minor:(NSInteger)minor build:(NSInteger)build
{
    if(self = [self initWithMajor:major minor:minor])
    {
        _build = build;
        
        if(_build < 0)
        {
            [NSException raise:@"ArgumentOutOfRangeException" format:@"Component cannot be less than 0"];
        }
    }
    return self;
}

- (id)initWithMajor:(NSInteger)major minor:(NSInteger)minor build:(NSInteger)build revision:(NSInteger)revision
{
    if(self = [self initWithMajor:major minor:minor build:build])
    {
        _revision = revision;
        
        if(_revision < 0)
        {
            [NSException raise:@"ArgumentOutOfRangeException" format:@"Component cannot be less than 0"];
        }
    }
    return self;
}

+ (BOOL)tryParse:(NSString *)input forVersion:(SRVersion **)version
{
    BOOL success = YES;
    
    if(input == nil || [input isEqualToString:@""] == YES)
    {
        return NO;
    }
    
    NSArray *components = [input componentsSeparatedByString:@"."];
    if([components count] < 2 || [components count] > 4)
    {
        return NO;
    }
    
    SRVersion *temp = [[SRVersion alloc] init];
    for (int i=0; i<[components count]; i++)
    {
        switch (i) {
            case 0:
                temp.major = [[components objectAtIndex:0] integerValue];
                break;
            case 1:
                temp.minor = [[components objectAtIndex:1] integerValue];
                break;
            case 2:
                temp.build = [[components objectAtIndex:2] integerValue];
                break;
            case 3:
                temp.revision = [[components objectAtIndex:3] integerValue];
                break;
            default:
                break;
        }
    }
    *version = temp;
    
    return success;
}

@end
