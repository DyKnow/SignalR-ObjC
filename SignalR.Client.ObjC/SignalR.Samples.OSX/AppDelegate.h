//
//  AppDelegate.h
//  SignalR.Samples.OSX
//
//  Created by Alex Billingsley on 1/17/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SignalR.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (strong, nonatomic, readwrite) SRConnection *connection;
@property (assign) IBOutlet NSWindow *window;

@end
