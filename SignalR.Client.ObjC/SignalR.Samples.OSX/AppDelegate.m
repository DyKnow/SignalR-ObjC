//
//  AppDelegate.m
//  SignalR.Samples.OSX
//
//  Created by Alex Billingsley on 1/17/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import "AppDelegate.h"
#import "Router.h"

@implementation AppDelegate

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    _connection = [SRConnection connectionWithURL:[[Router sharedRouter].server_url stringByAppendingFormat:@"streaming-connection"]];
    _connection.started = ^{
        NSLog(@"Connection Opened");
    };
    _connection.received = ^(NSString * data){
        NSLog(@"%@",data);
    };
    _connection.closed = ^{
       NSLog(@"Connection Closed");
    };
    _connection.error = ^(NSError *error){
         NSLog(@"%@",[NSString stringWithFormat:@"Connection Error: %@",error.localizedDescription]);
    };
    [_connection start];
}

@end
