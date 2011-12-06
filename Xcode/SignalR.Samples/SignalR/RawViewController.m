//
//  RawViewController.m
//  SignalR
//
//  Created by Alex Billingsley on 11/3/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "RawViewController.h"

@interface RawViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@end

@implementation RawViewController

@synthesize serverName, meField, privateMessageField, privateMessageToField, messageField, messageTable;

@synthesize detailItem = _detailItem;
@synthesize masterPopoverController = _masterPopoverController;

#pragma mark - View Actions

- (IBAction)connectClicked:(id)sender
{
    connection = [SRConnection connectionWithURL:serverName.text];
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
    
    NSString *json = [[SBJsonWriter new] stringWithObject:message];
    [connection send:json];
}

- (IBAction)broadcastClicked:(id)sender
{
    NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
    [message setObject:[NSNumber numberWithInt:1] forKey:@"type"];
    [message setObject:messageField.text forKey:@"value"];
    
    NSString *json = [[SBJsonWriter new] stringWithObject:message];
    [connection send:json];
}

- (IBAction)enternameClicked:(id)sender
{
    NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
    [message setObject:[NSNumber numberWithInt:2] forKey:@"type"];
    [message setObject:messageField.text forKey:@"value"];
    
    NSString *json = [[SBJsonWriter new] stringWithObject:message];
    [connection send:json];
}

- (IBAction)sendToUserClicked:(id)sender
{
    NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
    [message setObject:[NSNumber numberWithInt:3] forKey:@"type"];
    [message setObject:[NSString stringWithFormat:@"%@|%@",privateMessageToField.text,privateMessageField.text] forKey:@"value"];
    
    NSString *json = [[SBJsonWriter new] stringWithObject:message];
    [connection send:json];
}

- (IBAction)joingroupClicked:(id)sender
{
    NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
    [message setObject:[NSNumber numberWithInt:4] forKey:@"type"];
    [message setObject:messageField.text forKey:@"value"];

    NSString *json = [[SBJsonWriter new] stringWithObject:message];
    [connection send:json];
}

- (IBAction)leavegroupClicked:(id)sender
{
    NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
    [message setObject:[NSNumber numberWithInt:5] forKey:@"type"];
    [message setObject:messageField.text forKey:@"value"];
    
    NSString *json = [[SBJsonWriter new] stringWithObject:message];
    [connection send:json];
}

- (IBAction)sendToGroupClicked:(id)sender
{
    NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
    [message setObject:[NSNumber numberWithInt:6] forKey:@"type"];
    [message setObject:[NSString stringWithFormat:@"%@|%@",privateMessageToField.text,privateMessageField.text] forKey:@"value"];
    
    NSString *json = [[SBJsonWriter new] stringWithObject:message];
    [connection send:json];
}

- (IBAction)stopClicked:(id)sender
{
    [connection stop];
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
}

- (void)SRConnection:(SRConnection *)connection didReceiveData:(NSString *)data
{
    NSLog(@"Connection Received Data: %@",data);
    [messagesReceived addObject:data];
    [messageTable reloadData];
}

- (void)SRConnectionDidClose:(SRConnection *)connection
{
    NSLog(@"Connection CLOSED");
}

- (void)SRConnection:(SRConnection *)connection didReceiveError:(NSError *)error
{
    //NSLog(@"Connection Error: %@",error.localizedDescription);
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
