//
//  RawViewController.m
//  SignalR
//
//  Created by Alex Billingsley on 11/3/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "RawViewController.h"
#import "Router.h"

@implementation RawViewController

@synthesize meField, privateMessageField, privateMessageToField, messageField, messageTable;

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
    // Return YES for supported orientations
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
    server = [server stringByAppendingFormat:@"raw-connection"];
    connection = [SRConnection connectionWithURL:server];
    [connection setDelegate:self];
    [connection start];
    
    if(messagesReceived == nil)
    {
        messagesReceived = [[NSMutableArray alloc] init];
    }
}

- (IBAction)sendClicked:(id)sender
{
    NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
    message[@"type"] = @0;
    message[@"value"] = meField.text;

    [connection send:message];
}

- (IBAction)broadcastClicked:(id)sender
{
    NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
    message[@"type"] = @1;
    message[@"value"] = messageField.text;
    
    [connection send:message];
}

- (IBAction)enternameClicked:(id)sender
{
    NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
    message[@"type"] = @2;
    message[@"value"] = messageField.text;
    
    [connection send:message];
}

- (IBAction)sendToUserClicked:(id)sender
{
    NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
    message[@"type"] = @3;
    message[@"value"] = [NSString stringWithFormat:@"%@|%@",privateMessageToField.text,privateMessageField.text];
    
    [connection send:message];
}

- (IBAction)joingroupClicked:(id)sender
{
    NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
    message[@"type"] = @4;
    message[@"value"] = messageField.text;

    [connection send:message];
}

- (IBAction)leavegroupClicked:(id)sender
{
    NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
    message[@"type"] = @5;
    message[@"value"] = messageField.text;
    
   [connection send:message];
}

- (IBAction)sendToGroupClicked:(id)sender
{
    NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
    message[@"type"] = @6;
    message[@"value"] = [NSString stringWithFormat:@"%@|%@",privateMessageToField.text,privateMessageField.text];
    
    [connection send:message];
}

- (IBAction)stopClicked:(id)sender
{
    [connection stop];
}

#pragma mark - 
#pragma mark SRConnection Delegate

- (void)SRConnectionDidOpen:(SRConnection *)connection
{
    [messagesReceived insertObject:@"Connection Opened" atIndex:0];
    [messageTable reloadData];
}

- (void)SRConnection:(SRConnection *)connection didReceiveData:(id)data
{
    if (data != nil) {
        if([data isKindOfClass:[NSDictionary class]]) {
            [messagesReceived insertObject:data[@"data"] atIndex:0];
        } else {
            [messagesReceived insertObject:[NSString stringWithFormat:@"%@",data] atIndex:0];
        }
        [messageTable reloadData];
    }
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
