//
//  SRHubProxyTests.m
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 8/9/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SignalR.h"
//#import "NSDictionary+QueryString.h"

@interface SRHubProxyTests : XCTestCase

@end

@implementation SRHubProxyTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

#pragma mark -
#pragma mark Subscriptions

- (void)testSubscribingToNothingThrows {
    
    id mockConnection = [OCMockObject mockForProtocol:@protocol(SRConnectionInterface)];
    id hub = [[SRHubProxy alloc] initWithConnection:mockConnection hubName:@"myHub"];
    @try {
        [hub on:nil perform:nil selector:nil];
        XCTFail(@"Event Name must not be nil");
    }
    @catch (NSException *exception) {
        
    }
}

- (void)testSubscribingToEmptyStringThrows {
    id mockConnection = [OCMockObject mockForProtocol:@protocol(SRConnectionInterface)];
    id hub = [[SRHubProxy alloc] initWithConnection:mockConnection hubName:@"myHub"];
    @try {
        [hub on:@"" perform:nil selector:nil];
        XCTFail(@"Event Name must not be empty");
    }
    @catch (NSException *exception) {
        
    }
}

/**
 * Test for adding support for custom query strings on hubs
 * SRHubConnection should allow for custom query strings
 * https://github.com/SignalR/SignalR/commit/59de15e96adc220375e5c4b203056544f3e8be82
 */
/*- (void)testCustomQueryStringRaw
{
    SRHubConnection *connection = [SRHubConnection connectionWithURL:@"http://foo/" queryString:@"a=b"];    
    [connection createHubProxy:@"CustomQueryHub"];
    [connection start];

    NSString *result = [[NSDictionary dictionaryWithFormEncodedString:connection.queryString] objectForKey:@"a"];
    STAssertTrue([result isEqualToString:@"b"], @"Expected a 'b'");
}*/

/**
 * Test for adding support for custom query strings on hubs
 * SRHubConnection should allow for custom query strings
 * https://github.com/SignalR/SignalR/commit/59de15e96adc220375e5c4b203056544f3e8be82
 */
/*- (void)testCustomQueryString
{

    NSMutableDictionary *qs = [NSMutableDictionary dictionary];
    [qs setObject:@"b" forKey:@"a"];
    SRHubConnection *connection = [SRHubConnection connectionWithURL:@"http://foo/" query:qs];
    [connection createHubProxy:@"CustomQueryHub"];
    [connection start];

    NSString *result = [[NSDictionary dictionaryWithFormEncodedString:connection.queryString] objectForKey:@"a"];
    STAssertTrue([result isEqualToString:@"b"], @"Expected a 'b'");
}*/

@end
