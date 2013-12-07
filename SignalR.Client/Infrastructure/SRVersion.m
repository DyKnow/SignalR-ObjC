//
//  SRVersion.m
//  SignalR
//
//  Created by Alex Billingsley on 1/10/12.
//  Copyright (c) 2011 DyKnow LLC. (http://dyknow.com/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
//  documentation files (the "Software"), to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and 
//  to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of 
//  the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
//  THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
//  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
//  DEALINGS IN THE SOFTWARE.
//

#import "SRVersion.h"

@interface SRVersion ()

@end

@implementation SRVersion

- (instancetype)init {
    if(self = [super init]) {
        _build = 0;
        _major = 0;
        _majorRevision = 0;
        _minor = 0;
        _minorRevision = 0;
        _revision = 0;
    }
    return self;
}

- (instancetype)initWithMajor:(NSInteger)major minor:(NSInteger)minor {
    if(self = [self init]) {
        _major = major;
        _minor = minor;
        
        if(_major < 0 || _minor < 0) {
            [NSException raise:NSInvalidArgumentException format:NSLocalizedString(@"Component cannot be less than 0",@"NSInvalidArgumentException")];
        }
    }
    return self;
}

- (instancetype)initWithMajor:(NSInteger)major minor:(NSInteger)minor build:(NSInteger)build {
    if(self = [self initWithMajor:major minor:minor]) {
        _build = build;
        
        if(_build < 0) {
            [NSException raise:NSInvalidArgumentException format:NSLocalizedString(@"Component cannot be less than 0",@"NSInvalidArgumentException")];
        }
    }
    return self;
}

- (instancetype)initWithMajor:(NSInteger)major minor:(NSInteger)minor build:(NSInteger)build revision:(NSInteger)revision {
    if(self = [self initWithMajor:major minor:minor build:build]) {
        _revision = revision;
        
        if(_revision < 0) {
            [NSException raise:NSInvalidArgumentException format:NSLocalizedString(@"Component cannot be less than 0",@"NSInvalidArgumentException")];
        }
    }
    return self;
}

+ (BOOL)tryParse:(NSString *)input forVersion:(SRVersion **)version {
    BOOL success = YES;
    
    if(input == nil || [input isEqualToString:@""] == YES) {
        return NO;
    }
    
    NSArray *components = [input componentsSeparatedByString:@"."];
    if([components count] < 2 || [components count] > 4) {
        return NO;
    }
    
    SRVersion *temp = [[SRVersion alloc] init];
    for (int i=0; i<[components count]; i++) {
        switch (i) {
            case 0:
                temp.major = [components[0] integerValue];
                break;
            case 1:
                temp.minor = [components[1] integerValue];
                break;
            case 2:
                temp.build = [components[2] integerValue];
                break;
            case 3:
                temp.revision = [components[3] integerValue];
                break;
            default:
                break;
        }
    }
    *version = temp;
    
    return success;
}

- (BOOL)isEqual:(id)object {
    
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[SRVersion class]]) {
        return NO;
    }
    
    return (self.major == [(SRVersion *)object major] &&
            self.minor == [(SRVersion *)object minor] &&
            self.build == [(SRVersion *)object build] &&
            self.revision == [(SRVersion *)object revision]);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%ld.%ld.%ld.%ld",(long)_major,(long)_minor,(long)_build,(long)_revision];
}

@end
