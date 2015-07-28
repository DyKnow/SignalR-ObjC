//
//  SRHubConnectionTests.m
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 8/2/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SignalR.h"

@interface SRHubConnectionTests : XCTestCase

@end

@implementation SRHubConnectionTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

/*- (void)testThrowIfCreateProxyAfterConnectionStarts
{
    SRHubConnection *connection  = [SRHubConnection connectionWithURL:@"http://site/"];
    
    [connection start];
    STAssertThrowsSpecificNamed([connection createProxy:@"demo"], NSException, NSInternalInconsistencyException, @"Create proxy after start connection succeeded when it was expected to throw an exception") ;
}*/

@end
