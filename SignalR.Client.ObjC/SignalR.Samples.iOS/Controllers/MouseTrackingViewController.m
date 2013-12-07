//
//  MouseTrackingViewController.m
//  SignalR
//
//  Created by Alex Billingsley on 11/3/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "MouseTrackingViewController.h"
#import "Router.h"

@interface MouseTrackingViewController ()

- (void)moveMouse:(id)id x:(id)x y:(id)y;

@end

@implementation MouseTrackingViewController

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
    [_connection stop];
    _hub = nil;
    _connection.delegate = nil;
    _connection = nil;
    
    [super viewDidDisappear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if(_data == nil)
    {
        _data = [NSMutableArray array];
    }
    
    __weak __typeof(&*self)weakSelf = self;
    _connection = [SRHubConnection connectionWithURL:[Router sharedRouter].server_url];
    _hub = [_connection createHubProxy:@"MouseTracking"];
    [_hub on:@"move" perform:self selector:@selector(moveMouse:x:y:)];
    _connection.started = ^{
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        [strongSelf.data insertObject:@"Connection Opened" atIndex:0];
        [strongSelf.tableView reloadData];
    };
    _connection.received = ^(NSDictionary * data){
        //__strong __typeof(&*weakSelf)strongSelf = weakSelf;
        //[strongSelf.data insertObject:data atIndex:0];
        //[self.tableView reloadData];
    };
    _connection.closed = ^{
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        [strongSelf.data insertObject:@"Connection Closed" atIndex:0];
        [strongSelf.tableView reloadData];
    };
    _connection.error = ^(NSError *error){
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        [strongSelf.data insertObject:error.localizedDescription atIndex:0];
        [strongSelf.tableView reloadData];
    };
    [_connection start];
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedString(@"Mouse Tracking", @"Mouse Tracking");
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    return [self.data count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = (self.data)[indexPath.row];
    
    return cell;
}

#pragma mark - 
#pragma mark Mouse Tracking Sample Project

- (void)moveMouse:(id)id x:(id)x y:(id)y
{
    [self.data insertObject:[NSString stringWithFormat:@"Mouse Number: %@ Moved X:%@ Y:%@",id,x,y] atIndex:0];
    [self.tableView reloadData];
}

@end