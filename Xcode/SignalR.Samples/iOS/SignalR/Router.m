//
//  Router.m
//  SignalR
//
//  Created by Alex Billingsley on 1/11/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import "Router.h"

@interface Router()

/**
 * Attempts to read the server route from the environments plist
 * returns the server route based on build configuration, if no environments plist is found
 */
- (void)routeForEnvironment;

#define kServer @"server"

@end

static Router *sharedRouter = nil;

@implementation Router

@synthesize server_url = _server_url;

+ (Router *)sharedRouter 
{
	if (sharedRouter == nil) {
		sharedRouter = [[Router alloc] init];
        [sharedRouter routeForEnvironment];
	}
	return sharedRouter;
}

- (void)routeForEnvironment
{
    NSString *configuration = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"Configuration"];
    NSString *enviornmentPlist = [[NSBundle mainBundle] pathForResource:@"Environments" ofType:@"plist"];
    NSDictionary *environments = [[NSDictionary alloc] initWithContentsOfFile:enviornmentPlist];
    if(environments)
    {
        NSDictionary *environment = [environments objectForKey:configuration];
        _server_url = [environment valueForKey:kServer];
    }
    else
    {
        _server_url = @"";
    }
}

@end
