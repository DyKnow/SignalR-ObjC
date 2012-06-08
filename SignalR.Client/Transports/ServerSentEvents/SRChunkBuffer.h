//
//  SRChunkBuffer.h
//  SignalR.Samples
//
//  Created by Alex Billingsley on 6/8/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SRChunkBuffer : NSObject

@property (assign, nonatomic, readwrite) int offset;
@property (strong, nonatomic, readwrite) NSMutableString *buffer;
@property (strong, nonatomic, readwrite) NSMutableString *lineBuilder;

- (BOOL)hasChunks;
- (void)add:(id)buffer length:(int)length;
- (NSString *)readLine;

@end
