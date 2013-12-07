//
//  ChatViewController.m
//  SignalR
//
//  Created by Alex Billingsley on 11/3/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "ChatViewController.h"
#import "Router.h"

@interface ChatViewController ()
{
    NSString *name;
    NSString *hash;
    NSString *room;
}

- (void)addUser:(id)user exists:(BOOL)exists;

@end

@implementation ChatViewController

@synthesize messageField, messageTable;

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [connection stop];
    hub = nil;
    connection.delegate = nil;
    connection = nil;

    [super viewDidDisappear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark -
#pragma mark TableView datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    return [messagesReceived count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = messagesReceived[indexPath.row];
    
    return cell;
}

#pragma mark - 
#pragma mark View Actions

- (IBAction)connectClicked:(id)sender
{
    NSString *server = [Router sharedRouter].server_url;
    connection = [SRHubConnection connectionWithURL:server];
    hub = [connection createHubProxy:@"Chat"];
    
    [hub setMember:@"focus" object:@YES];
    [hub setMember:@"unread" object:@0];
    
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
    [hub invoke:@"Send" withArgs:@[messageField.text]];
    [messageField setText:@""];
}

#pragma mark - 
#pragma mark Chat Sample Project

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

-(void)refreshRoom:(id)inRoom
{
    [self clearMessages];
    [self clearUsers];
    
    [hub invoke:@"GetUsers" withArgs:@[] completionHandler:^(id users) {
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
                [self addMessage:[NSString stringWithFormat:@"%@ (%@)",r[@"Name"],r[@"Count"]] type:nil];
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
    NSString *userName = [NSString stringWithFormat:@"%@",user[@"Name"]];

    if(!exists && ([name isEqualToString:userName] == NO))
    {
        //NSString *userId = [NSString stringWithFormat:@"u-%@",[user objectForKey:@"Name"]];
        [self addMessage:[NSString stringWithFormat:@"%@ just entered %@",userName,room] type:nil];
    }
}

- (void)changeUserName:(id)oldUser newUser:(id)newUser
{
    [self refreshUsers];
    NSString *newUserName = [NSString stringWithFormat:@"%@",newUser[@"Name"]];
    
    name = newUserName;
    
    if([newUserName isEqualToString:name])
    {
        [self addMessage:[NSString stringWithFormat:@"Your name is now %@",newUserName] type:@"notification"];
    }
    else
    {
        NSString *oldUserName = [NSString stringWithFormat:@"%@",oldUser[@"Name"]];
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
    NSString *userName = [NSString stringWithFormat:@"%@",user[@"Name"]];
    [self addMessage:[NSString stringWithFormat:@"%@ left the room",userName] type:nil];
}

#pragma mark - 
#pragma mark SRConnection Delegate

- (void)SRConnectionDidOpen:(SRConnection *)connection
{
    [messagesReceived insertObject:@"Connection Opened" atIndex:0];
    [hub invoke:@"Join" withArgs:@[]];
    [messageTable reloadData];
}

- (void)SRConnection:(SRConnection *)connection didReceiveData:(id)data
{
    //[messagesReceived insertObject:data atIndex:0];
    //[messageTable reloadData];
}

- (void)SRConnectionDidClose:(SRConnection *)connection
{
    [messagesReceived insertObject:@"Connection Closed" atIndex:0];
    [messageTable reloadData];
}

- (void)SRConnection:(SRConnection *)connection didReceiveError:(NSError *)error
{
    //[messagesReceived insertObject:[NSString stringWithFormat:@"Connection Error: %@",error.localizedDescription] atIndex:0];
    //[messageTable reloadData];
}

@end