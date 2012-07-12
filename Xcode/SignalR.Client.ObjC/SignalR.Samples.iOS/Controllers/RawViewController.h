//
//  RawViewController.h
//  SignalR
//
//  Created by Alex Billingsley on 11/3/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SignalR.h"

@interface RawViewController : UIViewController <UISplitViewControllerDelegate, SRConnectionDelegate>
{
    SRConnection *connection;
    NSMutableArray *messagesReceived;
}
@property (nonatomic, strong) IBOutlet UITableView *messageTable;
@property (nonatomic, strong) IBOutlet UITextField *messageField;
@property (nonatomic, strong) IBOutlet UITextField *meField;
@property (nonatomic, strong) IBOutlet UITextField *privateMessageField;
@property (nonatomic, strong) IBOutlet UITextField *privateMessageToField;

- (IBAction)connectClicked:(id)sender;

- (IBAction)broadcastClicked:(id)sender;
- (IBAction)enternameClicked:(id)sender;
- (IBAction)joingroupClicked:(id)sender;
- (IBAction)leavegroupClicked:(id)sender;

- (IBAction)sendClicked:(id)sender;

- (IBAction)sendToUserClicked:(id)sender;
- (IBAction)sendToGroupClicked:(id)sender;

- (IBAction)stopClicked:(id)sender;

@end
