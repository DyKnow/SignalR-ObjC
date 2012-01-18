//
//  StreamingViewController.h
//  SignalR
//
//  Created by Alex Billingsley on 11/3/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SignalR-iOS/SignalR.h>

@interface StreamingViewController : UIViewController<UISplitViewControllerDelegate, SRConnectionDelegate>
{
    SRConnection *connection;
    NSMutableArray *messagesReceived;
}
@property (nonatomic, strong) IBOutlet UITableView *messageTable;

- (IBAction)connectClicked:(id)sender;

@end
