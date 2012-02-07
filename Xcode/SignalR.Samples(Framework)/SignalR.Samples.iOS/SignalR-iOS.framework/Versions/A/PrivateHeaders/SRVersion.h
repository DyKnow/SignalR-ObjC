//
//  SRVersion.h
//  SignalR
//
//  Created by Alex Billingsley on 1/10/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SRVersion : NSObject

@property (assign, nonatomic, readwrite) NSInteger build;
@property (assign, nonatomic, readwrite) NSInteger major;
@property (assign, nonatomic, readwrite) NSInteger majorRevision;
@property (assign, nonatomic, readwrite) NSInteger minor;
@property (assign, nonatomic, readwrite) NSInteger minorRevision;
@property (assign, nonatomic, readwrite) NSInteger revision;

- (id)initWithMajor:(NSInteger)major minor:(NSInteger)minor;
- (id)initWithMajor:(NSInteger)major minor:(NSInteger)minor build:(NSInteger)build;
- (id)initWithMajor:(NSInteger)major minor:(NSInteger)minor build:(NSInteger)build revision:(NSInteger)revision;

+ (BOOL)tryParse:(NSString *)input forVersion:(SRVersion **)version;

@end
