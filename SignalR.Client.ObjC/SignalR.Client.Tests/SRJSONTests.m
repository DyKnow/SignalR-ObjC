//
//  SRJSONTests.m
//  SignalR
//
//  Created by Alex Billingsley on 7/30/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "NSObject+SRJSON.h"
#import "SRSerializable.h"

@interface InvalidModel : NSObject

@end

@implementation InvalidModel

@end

@interface InvalidConformingModel : NSObject <SRSerializable>

@end

@implementation InvalidConformingModel

- (id)proxyForJson
{
    return nil;
}

@end



@interface SRJSONTests : SenTestCase

@end

@implementation SRJSONTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

/**
 * Test for issue #96
 * SRJSONRepresentation should throw if a returned object is nil
 * https://github.com/DyKnow/SignalR-ObjC/issues/96
 */
- (void)testThrowWhenEnsureFoundationObjectShouldReturnNil
{
    InvalidModel *model = [[InvalidModel alloc] init];
    STAssertThrowsSpecificNamed([model SRJSONRepresentation], NSException, NSInternalInconsistencyException, @"SRJSONRepresentation succeeded when it was expected to throw an exception") ;
}

/**
 * Test for issue #96
 * SRJSONRepresentation should throw if a returned object is nil
 * https://github.com/DyKnow/SignalR-ObjC/issues/96
 */
- (void)testThrowWhenEnsureFoundationObjectShouldReturnNil_NSArray
{
    NSArray *nonConformingArray = @[[[InvalidModel alloc] init]];
    STAssertThrowsSpecificNamed([nonConformingArray SRJSONRepresentation], NSException, NSInternalInconsistencyException, @"SRJSONRepresentation succeeded when it was expected to throw an exception") ;
}

/**
 * Test for issue #96
 * SRJSONRepresentation should throw if a returned object is nil
 * https://github.com/DyKnow/SignalR-ObjC/issues/96
 */
- (void)testThrowWhenEnsureFoundationObjectShouldReturnNil_NSDictionary
{
    NSDictionary *nonConformingDictionary = @{@"somekey": [[InvalidModel alloc] init]};
    STAssertThrowsSpecificNamed([nonConformingDictionary SRJSONRepresentation], NSException, NSInternalInconsistencyException, @"SRJSONRepresentation succeeded when it was expected to throw an exception") ;
}

/**
 * Test for issue #96
 * SRJSONRepresentation should throw if a returned object is nil
 * https://github.com/DyKnow/SignalR-ObjC/issues/96
 */
- (void)testThrowWhenEnsureFoundationObjectShouldReturnNil_ConformingObjectReturnsNil
{
    InvalidConformingModel *model = [[InvalidConformingModel alloc] init];
    STAssertThrowsSpecificNamed([model SRJSONRepresentation], NSException, NSInternalInconsistencyException, @"SRJSONRepresentation succeeded when it was expected to throw an exception") ;
}

@end
