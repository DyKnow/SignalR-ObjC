//
//  ConnectionStatusViewController.m
//  SignalR
//
//  Created by Alex Billingsley on 11/3/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "ConnectionStatusViewController.h"
#import "Router.h"

@implementation ConnectionStatusViewController

@synthesize messageTable;

- (void)dealloc
{
    [connection stop];
    hub = nil;
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
    connection = [SRHubConnection connectionWithURL:server];
    hub = [connection createProxy:@"Status"];
    [hub on:@"joined" perform:self selector:@selector(joined:when:)];
    [hub on:@"rejoined" perform:self selector:@selector(rejoined:when:)];
    [hub on:@"leave" perform:self selector:@selector(leave:when:)];
    
    [connection setDelegate:self];
    [connection start];
    
    if(messagesReceived == nil)
    {
        messagesReceived = [[NSMutableArray alloc] init];
    }
}

#pragma mark - 
#pragma mark Connect Disconnect Sample Project

- (void)joined:(NSString *)id when:(NSString *)when
{
    if([id isEqualToString:connection.connectionId])
    {
        [messagesReceived insertObject:[NSString stringWithFormat:@"I joined at: %@",when] atIndex:0];
    }
    else
    {
        [messagesReceived insertObject:[NSString stringWithFormat:@"%@ joined at: %@",id,when] atIndex:0];
    }
    [messageTable reloadData];
}

- (void)rejoined:(NSString *)id when:(NSString *)when
{
    [messagesReceived insertObject:[NSString stringWithFormat:@"reconnected at: %@",when] atIndex:0];
    [messageTable reloadData];
}


- (void)leave:(NSString *)id when:(NSString *)when
{
    [messagesReceived insertObject:[NSString stringWithFormat:@"%@ left at: %@",id,when] atIndex:0];
    [messageTable reloadData];
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