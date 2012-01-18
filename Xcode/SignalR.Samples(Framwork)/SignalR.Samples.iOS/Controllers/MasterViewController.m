//
//  MasterViewController.m
//  TestMaster
//
//  Created by Alex Billingsley on 11/3/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "MasterViewController.h"

#import "RawViewController.h"
#import "StreamingViewController.h"
#import "ConnectionStatusViewController.h"
#import "MouseTrackingViewController.h"
#import "ChatViewController.h"

@implementation MasterViewController

@synthesize detailViewController = _detailViewController;

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
    self.clearsSelectionOnViewWillAppear = NO;
    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
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
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    NSUInteger row = indexPath.row;
    
    if (row == 0) {
        cell.textLabel.text = NSLocalizedString(@"Raw", @"");
    }
    else if (row == 1) {
        cell.textLabel.text = NSLocalizedString(@"Streaming", @"");
    }
    else if (row == 2) {
        cell.textLabel.text = NSLocalizedString(@"Connection Status", @"");
    }
    else if (row == 3) {
        cell.textLabel.text = NSLocalizedString(@"Chat", @"");
    }
    else if (row == 4) {
        cell.textLabel.text = NSLocalizedString(@"Mouse Tracking", @"");
    }
    return cell;
}

#pragma mark - 
#pragma mark TableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger row = indexPath.row;
    
    if (row == 0) {
        RawViewController *newDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"RawViewController"];
        self.detailViewController = newDetailViewController;
    }
    else if (row == 1) {
        StreamingViewController *newDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"StreamingViewController"];
        self.detailViewController = newDetailViewController;
    }
    else if (row == 2) {
        ConnectionStatusViewController *newDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ConnectionStatusViewController"];
        self.detailViewController = newDetailViewController;
    }
    else if (row == 3) {
        ChatViewController *newDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ChatViewController"];
        self.detailViewController = newDetailViewController;
    }
    else if (row == 4) {
        MouseTrackingViewController *newDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"MouseTrackingViewController"];
        self.detailViewController = newDetailViewController;
    }
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.detailViewController];
    
    // Update the split view controller's view controllers array.
    NSArray *viewControllers = [[NSArray alloc] initWithObjects:self.navigationController, navController, nil];
    self.splitViewController.viewControllers = viewControllers;
      
    self.detailViewController = [[self.splitViewController.viewControllers lastObject] topViewController];
}

@end
