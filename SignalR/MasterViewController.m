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
#import "VisionWebViewController.h"

@implementation MasterViewController

@synthesize detailViewController = _detailViewController;

#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 6;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    NSUInteger row = indexPath.row;
    
    if (row == 0) {
        cell.textLabel.text = @"Raw";
    }
    else if (row == 1) {
        cell.textLabel.text = @"Streaming";
    }
    else if (row == 2) {
        cell.textLabel.text = @"Connection Status";
    }
    else if (row == 3) {
        cell.textLabel.text = @"Chat";
    }
    else if (row == 4) {
        cell.textLabel.text = @"Mouse Tracking";
    }
    else if (row == 5) {
        cell.textLabel.text = @"Vision Web";
    }
    return cell;
}

#pragma mark - Table view delegate

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
    else if (row == 5) {
        VisionWebViewController *newDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VisionWebViewController"];
        self.detailViewController = newDetailViewController;
    }
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.detailViewController];
    
    // Update the split view controller's view controllers array.
    NSArray *viewControllers = [[NSArray alloc] initWithObjects:self.navigationController, navController, nil];
    self.splitViewController.viewControllers = viewControllers;
    
    self.detailViewController = [[self.splitViewController.viewControllers lastObject] topViewController];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.clearsSelectionOnViewWillAppear = NO;
    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    
   //self.detailViewController = [[self.splitViewController.viewControllers lastObject] topViewController];
   // [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionMiddle];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

@end
