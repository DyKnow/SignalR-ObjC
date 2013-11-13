//
//  SRChunkBufferTests.m
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 8/3/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "SRChunkBuffer.h"

@interface SRChunkBufferTests : SenTestCase

@end

@implementation SRChunkBufferTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testReturnsNullIfNoNewLineIfBuffer
{
    // Arrange
    SRChunkBuffer *buffer = [[SRChunkBuffer alloc] init];
    NSData *data = [[NSString stringWithFormat:@"hello world"] dataUsingEncoding:NSUTF8StringEncoding];
    
    // Act
    [buffer add:data];
    
    // Assert
    STAssertNil([buffer readLine], @"Expected nil received object");
}

- (void)testReturnsTextUpToNewLine
{
    // Arrange
    SRChunkBuffer *buffer = [[SRChunkBuffer alloc] init];
    NSData *data = [[NSString stringWithFormat:@"hello world\noy"] dataUsingEncoding:NSUTF8StringEncoding];
    
    // Act
    [buffer add:data];
    
    // Assert
    STAssertTrue([[buffer readLine] isEqualToString:@"hello world"], @"Expected to read first line only");
}

- (void)testCanReadMultipleLines
{
    // Arrange
    SRChunkBuffer *buffer = [[SRChunkBuffer alloc] init];
    NSData *data = [[NSString stringWithFormat:@"hel\nlo world\noy"] dataUsingEncoding:NSUTF8StringEncoding];
    
    // Act
    [buffer add:data];
    
    // Assert
    STAssertTrue([[buffer readLine] isEqualToString:@"hel"], @"Expected to read first line");
    STAssertTrue([[buffer readLine] isEqualToString:@"lo world"], @"Expected to read second line");
    STAssertNil([buffer readLine], @"Expected nil received object");
}

- (void)testWillCompleteNewLin
{
    // Arrange
    SRChunkBuffer *buffer = [[SRChunkBuffer alloc] init];
    NSData *data = [[NSString stringWithFormat:@"hello"] dataUsingEncoding:NSUTF8StringEncoding];
    [buffer add:data];
    STAssertNil([buffer readLine], @"Expected nil received object");
    data = [[NSString stringWithFormat:@"\n"] dataUsingEncoding:NSUTF8StringEncoding];
    [buffer add:data];
    STAssertTrue([[buffer readLine] isEqualToString:@"hello"], @"Expected to read first line only");
    data = [[NSString stringWithFormat:@"Another line"] dataUsingEncoding:NSUTF8StringEncoding];
    [buffer add:data];
    STAssertNil([buffer readLine], @"Expected nil received object");
    data = [[NSString stringWithFormat:@"\nnext"] dataUsingEncoding:NSUTF8StringEncoding];
    [buffer add:data];
    STAssertTrue([[buffer readLine] isEqualToString:@"Another line"], @"Expected to read first line only");
}

@end
