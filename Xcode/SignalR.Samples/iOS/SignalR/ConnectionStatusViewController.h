//
//  ConnectionStatusViewController.h
//  SignalR
//
//  Created by Alex Billingsley on 11/3/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SignalR.h"

@interface ConnectionStatusViewController : UIViewController<UISplitViewControllerDelegate, SRConnectionDelegate>
{
    SRHubConnection *connection;
    SRHubProxy *hub;
    NSMutableArray *messagesReceived;
}
@property (nonatomic, strong) IBOutlet UITableView *messageTable;
@property (nonatomic, strong) IBOutlet UITextField *serverName;

@property (strong, nonatomic) id detailItem;

- (IBAction)connectClicked:(id)sender;

@end