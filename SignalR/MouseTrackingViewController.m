//
//  MouseTrackingViewController.m
//  SignalR
//
//  Created by Alex Billingsley on 11/3/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "MouseTrackingViewController.h"

@interface MouseTrackingViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;

- (void)moveMouse:(id)id x:(id)x y:(id)y;
- (void)join;

@end

@implementation MouseTrackingViewController

@synthesize serverName, messageTable;

@synthesize detailItem = _detailItem;
@synthesize masterPopoverController = _masterPopoverController;

#pragma mark - View Actions

- (IBAction)connectClicked:(id)sender
{
    connection = [SRHubConnection connectionWithURL:serverName.text];
    hub = [connection createProxy:@"SignalR.Samples.Hubs.MouseTracking.MouseTracking"]; 
    [hub on:@"moveMouse" perform:self selector:@selector(moveMouse:x:y:)];
    [hub on:@"join" perform:self selector:@selector(join)];
    [connection start];
    
    if(messagesReceived == nil)
    {
        messagesReceived = [[NSMutableArray alloc] init];
    }
}

#pragma mark - Connect Disconnect Sample Project
- (void)moveMouse:(id)id x:(id)x y:(id)y
{
    [messagesReceived insertObject:[NSString stringWithFormat:@"Mouse Number: %@ Moved X:%@ Y:%@",id,x,y] atIndex:0];
    [messageTable reloadData];
}

- (void)join
{
    [messagesReceived insertObject:[NSString stringWithFormat:@"Joined"] atIndex:0];
    [messageTable reloadData];
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