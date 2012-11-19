//
//  ConnectionStatusViewController.h
//  SignalR
//
//  Created by Alex Billingsley on 11/3/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SignalR.h"

@interface ConnectionStatusViewController : UITableViewController<UISplitViewControllerDelegate>

@property (strong, nonatomic, readwrite) SRHubConnection *connection;
@property (strong, nonatomic, readwrite) SRHubProxy *hub;
@property (strong, nonatomic, readwrite) NSMutableArray *data;

@end