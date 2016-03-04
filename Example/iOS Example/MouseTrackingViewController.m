//
//  MouseTrackingViewController.m
//  SignalR.Client.ObjC Example
//
//  Created by Alex Billingsley on 3/3/16.
//
//

#import "MouseTrackingViewController.h"
#import "MouseTrackingConnection.h"

@interface MouseTrackingViewController ()

@property (strong, nonatomic, readwrite) NSMutableArray *data;

@end

@implementation MouseTrackingViewController

- (void)viewDidDisappear:(BOOL)animated {
    [[MouseTrackingConnection sharedConnection] stop];
    [super viewDidDisappear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if(_data == nil) {
        _data = [NSMutableArray array];
    }
    
    __weak __typeof(&*self)weakSelf = self;
    [[MouseTrackingConnection sharedConnection] setStarted:^{
        NSLog(@"Connection Opened");
        [[MouseTrackingConnection sharedConnection] join];
    }];
    [[MouseTrackingConnection sharedConnection] setReconnecting:^{
        NSLog(@"Connection Reconnecting");
    }];
    [[MouseTrackingConnection sharedConnection] setReconnected:^{
        NSLog(@"Connection Reconnected");
    }];
    [[MouseTrackingConnection sharedConnection] setConnectionSlow:^{
        NSLog(@"Connection Slow");
    }];
    [[MouseTrackingConnection sharedConnection] setReceived:^(NSString * data){
        NSLog(@"%@",data);
    }];
    [[MouseTrackingConnection sharedConnection] setError:^(NSError *error){
        NSLog(@"%@",[NSString stringWithFormat:@"Connection Error: %@",error.localizedDescription]);
    }];
    [[MouseTrackingConnection sharedConnection] setClosed:^(){
        NSLog(@"Connection Closed");
    }];
    [[MouseTrackingConnection sharedConnection] setMoveBlock:^(NSString *connectionId, NSNumber *x, NSNumber *y) {
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        [strongSelf.data insertObject:[NSString stringWithFormat:@"%@ Moved X:%@ Y:%@",connectionId, x, y] atIndex:0];
        [strongSelf.tableView reloadData];
    }];
    [[MouseTrackingConnection sharedConnection] start];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.data count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    NSString *object = self.data[indexPath.row];
    cell.textLabel.text = [object description];
    return cell;
}

@end
