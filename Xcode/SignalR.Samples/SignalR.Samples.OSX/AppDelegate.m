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
    NSString *server = [Router sharedRouter].server_url;
    server = [server stringByAppendingFormat:@"Streaming/Streaming.ashx"];
    connection = [SRConnection connectionWithURL:server];
    [connection setDelegate:self];
    
    [connection start];
}

#pragma mark - 
#pragma mark SRConnection Delegate

- (void)SRConnectionDidOpen:(SRConnection *)connection
{
    NSLog(@"Connection Opened");
}

- (void)SRConnection:(SRConnection *)connection didReceiveData:(NSString *)data
{
    NSLog(@"%@",data);
}

- (void)SRConnectionDidClose:(SRConnection *)connection
{
    NSLog(@"Connection Closed");
}

- (void)SRConnection:(SRConnection *)connection didReceiveError:(NSError *)error
{
    NSLog(@"%@",[NSString stringWithFormat:@"Connection Error: %@",error.localizedDescription]);
}

@end
