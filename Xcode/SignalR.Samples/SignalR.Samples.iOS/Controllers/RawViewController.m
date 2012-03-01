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

- (void)dealloc
{
    [connection stop];
    connection.delegate = nil;
    connection = nil;
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - 
#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
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
    
    cell.textLabel.text = [messagesReceived objectAtIndex:indexPath.row];
    
    return cell;
}

#pragma mark - 
#pragma mark View Actions

- (IBAction)connectClicked:(id)sender
{
    NSString *server = [Router sharedRouter].server_url;
    server = [server stringByAppendingFormat:@"Raw/Raw.ashx"];
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
    [message setObject:[NSNumber numberWithInt:0] forKey:@"type"];
    [message setObject:meField.text forKey:@"value"];

    NSString *json = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:message options:0 error:nil] encoding:NSUTF8StringEncoding];
    [connection send:json];
}

- (IBAction)broadcastClicked:(id)sender
{
    NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
    [message setObject:[NSNumber numberWithInt:1] forKey:@"type"];
    [message setObject:messageField.text forKey:@"value"];
    
   NSString *json = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:message options:0 error:nil] encoding:NSUTF8StringEncoding];
    [connection send:json];
}

- (IBAction)enternameClicked:(id)sender
{
    NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
    [message setObject:[NSNumber numberWithInt:2] forKey:@"type"];
    [message setObject:messageField.text forKey:@"value"];
    
    NSString *json = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:message options:0 error:nil] encoding:NSUTF8StringEncoding];
    [connection send:json];
}

- (IBAction)sendToUserClicked:(id)sender
{
    NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
    [message setObject:[NSNumber numberWithInt:3] forKey:@"type"];
    [message setObject:[NSString stringWithFormat:@"%@|%@",privateMessageToField.text,privateMessageField.text] forKey:@"value"];
    
    NSString *json = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:message options:0 error:nil] encoding:NSUTF8StringEncoding];
    [connection send:json];
}

- (IBAction)joingroupClicked:(id)sender
{
    NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
    [message setObject:[NSNumber numberWithInt:4] forKey:@"type"];
    [message setObject:messageField.text forKey:@"value"];

    NSString *json = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:message options:0 error:nil] encoding:NSUTF8StringEncoding];
    [connection send:json];
}

- (IBAction)leavegroupClicked:(id)sender
{
    NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
    [message setObject:[NSNumber numberWithInt:5] forKey:@"type"];
    [message setObject:messageField.text forKey:@"value"];
    
    NSString *json = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:message options:0 error:nil] encoding:NSUTF8StringEncoding];
    [connection send:json];
}

- (IBAction)sendToGroupClicked:(id)sender
{
    NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
    [message setObject:[NSNumber numberWithInt:6] forKey:@"type"];
    [message setObject:[NSString stringWithFormat:@"%@|%@",privateMessageToField.text,privateMessageField.text] forKey:@"value"];
    
    NSString *json = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:message options:0 error:nil] encoding:NSUTF8StringEncoding];
    [connection send:json];
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

- (void)SRConnection:(SRConnection *)connection didReceiveData:(NSString *)data
{
    [messagesReceived insertObject:data atIndex:0];
    [messageTable reloadData];
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
