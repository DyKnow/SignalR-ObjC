//
//  MasterViewController.m
//  iOS Example
//
//  Created by Alex Billingsley on 3/1/16.
//
//

#import "MasterViewController.h"

@interface MasterViewController ()

@property NSArray *objects;
@end

@implementation MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.objects = @[
        @{
            @"title": @"Persistent Connections",
            @"samples": @[
                @"Raw Connection",
                @"Streaming Connection",
            ]
        },
        @{
            @"title": @"Hub Connections",
            @"samples": @[
                //@"Chat",
                @"Connect Disconnect",
                //@"Counting",
                //@"Demo Hub",
                @"Drawing Pad",
                //@"Hub Connection API",
                //@"Message Loops",
                @"Mouse Tracking",
                //@"Realtime Broadcast",
                //@"Shape Share"
            ]
        }
    ];
    self.detailViewController = [[self.splitViewController.viewControllers lastObject] topViewController];
}

- (void)viewWillAppear:(BOOL)animated {
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    NSString *object = self.objects[indexPath.section][@"samples"][indexPath.row];
    
    UIViewController *controller = [[segue destinationViewController] topViewController];
    [controller setTitle:object];
    controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    controller.navigationItem.leftItemsSupplementBackButton = YES;
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.objects count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.objects[section][@"title"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.objects[section][@"samples"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    NSString *object = self.objects[indexPath.section][@"samples"][indexPath.row];
    cell.textLabel.text = [object description];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *object = self.objects[indexPath.section][@"samples"][indexPath.row];
    if ([object isEqualToString:@"Raw Connection"]) {
        [self performSegueWithIdentifier:@"RawConnection" sender:self];
    } else if ([object isEqualToString:@"Streaming Connection"]) {
        [self performSegueWithIdentifier:@"StreamingConnection" sender:self];
    } else if ([object isEqualToString:@"Connect Disconnect"]) {
        [self performSegueWithIdentifier:@"ConnectDisconnect" sender:self];
    } else if ([object isEqualToString:@"Drawing Pad"]) {
        [self performSegueWithIdentifier:@"DrawingPad" sender:self];
    } else if ([object isEqualToString:@"Mouse Tracking"]) {
        [self performSegueWithIdentifier:@"MouseTracking" sender:self];
    }
}

@end
