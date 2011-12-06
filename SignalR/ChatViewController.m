//
//  ChatViewController.m
//  SignalR
//
//  Created by Alex Billingsley on 11/3/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "ChatViewController.h"

@interface ChatViewController ()
{
    NSString *name;
    NSString *hash;
    NSString *room;
}
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
- (void)addUser:(id)user exists:(BOOL)exists;

@end

@implementation ChatViewController

@synthesize serverName, messageField, messageTable;

@synthesize detailItem = _detailItem;
@synthesize masterPopoverController = _masterPopoverController;

#pragma mark - View Actions

- (IBAction)connectClicked:(id)sender
{
    connection = [SRHubConnection connectionWithURL:serverName.text];
    hub = [connection createProxy:@"SignalR.Samples.Hubs.Chat.Chat"];
    
    [hub setMember:@"focus" object:[NSNumber numberWithBool:YES]];
    [hub setMember:@"unread" object:[NSNumber numberWithInt:0]];
    
    [hub on:@"refreshRoom" perform:self selector:@selector(refreshRoom:)];
    [hub on:@"showRooms" perform:self selector:@selector(showRooms:)];
    [hub on:@"addMessageContent" perform:self selector:@selector(addMessageContent:content:)];
    [hub on:@"addMessage" perform:self selector:@selector(addMessage:name:message:)];
    [hub on:@"addUser" perform:self selector:@selector(addUser:exists:)];
    [hub on:@"changeUserName" perform:self selector:@selector(changeUserName:newUser:)];
    [hub on:@"sendPrivateMessage" perform:self selector:@selector(sendPrivateMessage:to:message:)];
    [hub on:@"sendMeMessage" perform:self selector:@selector(sendMeMessage:message:)];
    [hub on:@"leave" perform:self selector:@selector(leave:)];

    [connection setDelegate:self];
    [connection start];
    
    if(messagesReceived == nil)
    {
        messagesReceived = [[NSMutableArray alloc] init];
    }
}

- (IBAction)sendClicked:(id)sender
{
    [hub invoke:@"Send" withArgs:[NSArray arrayWithObjects:messageField.text, nil]];
    [messageField setText:@""];
}

#pragma mark - Chat Sample Project

- (void)clearMessages
{
    [messagesReceived removeAllObjects];
    [messageTable reloadData];
}

- (void)refreshMessages
{
    [messageTable reloadData];
}

- (void)clearUsers
{
    //[usersReceived removeAllObjects];
    //[userTable reloadData];
}

- (void)refreshUsers
{
    //[userTable reloadData];
}

- (void)addMessage:(NSString *)content type:(id)type
{
    [messagesReceived addObject:content];
    [self refreshMessages];
}

//TODO: Handle GetUsers Callback
-(void)refreshRoom:(id)inRoom
{
    [self clearMessages];
    [self clearUsers];
    
    [hub invoke:@"GetUsers" withArgs:[NSArray arrayWithObjects:nil] onCompletion:^(id users) {
        for(id user in users)
        {
            if([user isKindOfClass:[NSDictionary class]]){
                [self addUser:user exists:TRUE];
            }
            [self refreshUsers];
        }
    }];
    
    [self addMessage:[NSString stringWithFormat:@"Entered %@",inRoom] type:@"notification"];
    room = inRoom;
}

-(void)showRooms:(id)rooms
{
    if([rooms isKindOfClass:[NSArray class]])
    {
        if([rooms count] == 0)
        {
            [self addMessage:[NSString stringWithFormat:@"No rooms available"] type:@"notification"];
        }
        else
        {
            for (id r in rooms)
            {
                [self addMessage:[NSString stringWithFormat:@"%@ (%@)",[r objectForKey:@"Name"],[r objectForKey:@"Count"]] type:nil];
            }
        }
    }
}

- (void)addMessageContent:(id)id content:(id)content
{
    NSLog(@"addMessageContent");
}

- (void)addMessage:(id)id name:(id)inName message:(id)message
{
    [self addMessage:[NSString stringWithFormat:@"%@: %@",inName,message] type:nil];
    [self refreshMessages];
}

- (void)addUser:(id)user exists:(BOOL)exists
{
    NSString *userName = [NSString stringWithFormat:@"%@",[user objectForKey:@"Name"]];

    if(!exists && ([name isEqualToString:userName] == NO))
    {
        //NSString *userId = [NSString stringWithFormat:@"u-%@",[user objectForKey:@"Name"]];
        [self addMessage:[NSString stringWithFormat:@"%@ just entered %@",userName,room] type:nil];
    }
}

- (void)changeUserName:(id)oldUser newUser:(id)newUser
{
    [self refreshUsers];
    NSString *newUserName = [NSString stringWithFormat:@"%@",[newUser objectForKey:@"Name"]];
    
    name = newUserName;
    
    if([newUserName isEqualToString:name])
    {
        [self addMessage:[NSString stringWithFormat:@"Your name is now %@",newUserName] type:@"notification"];
    }
    else
    {
        NSString *oldUserName = [NSString stringWithFormat:@"%@",[oldUser objectForKey:@"Name"]];
        [self addMessage:[NSString stringWithFormat:@"%@'s nick has changed to %@",oldUserName,newUserName] type:@"notification"];
    }
}

- (void)sendMeMessage:(id)inName message:(id)message
{
    [self addMessage:[NSString stringWithFormat:@"*%@* %@",inName,message] type:@"notification"];
}

- (void)sendPrivateMessage:(id)from to:(id)to message:(id)message
{
    [self addMessage:[NSString stringWithFormat:@"*%@* %@",from,message] type:@"pm"];
}

- (void)leave:(id)user
{
    NSString *userName = [NSString stringWithFormat:@"%@",[user objectForKey:@"Name"]];
    [self addMessage:[NSString stringWithFormat:@"%@ left the room",userName] type:nil];
}


#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [messagesReceived count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    cell.textLabel.text = [messagesReceived objectAtIndex:indexPath.row];
    
    return cell;
}


#pragma SRConnection Delegate

- (void)SRConnectionDidOpen:(SRConnection *)connection
{
    NSLog(@"Connection OPENED");
    [hub invoke:@"Join" withArgs:[NSArray arrayWithObjects: nil]];
}

- (void)SRConnectionDidClose:(SRConnection *)connection
{
    NSLog(@"Connection CLOSED");
}

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }
    
    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }         
}

- (void)configureView
{
    // Update the user interface for the detail item.
    
    if (self.detailItem) {
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}
@end