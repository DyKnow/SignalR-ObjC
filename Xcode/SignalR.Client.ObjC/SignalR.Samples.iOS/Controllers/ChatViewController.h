//
//  ChatViewController.h
//  SignalR
//
//  Created by Alex Billingsley on 11/3/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SignalR.h"

@interface ChatViewController : UIViewController <UISplitViewControllerDelegate, SRConnectionDelegate>
{
    SRHubConnection *connection;
    SRHubProxy *hub;
    NSMutableArray *messagesReceived;
}
@property (nonatomic, strong) IBOutlet UITableView *messageTable;
@property (nonatomic, strong) IBOutlet UITextField *messageField;

- (IBAction)connectClicked:(id)sender;
- (IBAction)sendClicked:(id)sender;

@end
