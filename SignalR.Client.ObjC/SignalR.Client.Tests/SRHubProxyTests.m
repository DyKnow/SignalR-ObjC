//
//  SRHubProxyTests.m
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 8/9/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "SignalR.h"
//#import "NSDictionary+QueryString.h"

@interface SRHubProxyTests : SenTestCase

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
