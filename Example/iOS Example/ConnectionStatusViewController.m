//
//  ConnectionStatusViewController.m
//  SignalR.Client.ObjC Example
//
//  Created by Alex Billingsley on 3/2/16.
//
//

#import "ConnectionStatusViewController.h"
#import "ConnectionStatusConnection.h"

@interface ConnectionStatusViewController ()

@property (strong, nonatomic, readwrite) NSMutableArray *data;

@end

@implementation ConnectionStatusViewController

- (void)viewDidDisappear:(BOOL)animated {
    [[ConnectionStatusConnection sharedConnection] stop];
    [super viewDidDisappear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if(_data == nil) {
        _data = [NSMutableArray array];
    }
    
    __weak __typeof(&*self)weakSelf = self;
    [[ConnectionStatusConnection sharedConnection] setStarted:^{
        
        NSLog(@"Connection Opened");
    }];
    [[ConnectionStatusConnection sharedConnection] setReconnecting:^{
        NSLog(@"Connection Reconnecting");
    }];
    [[ConnectionStatusConnection sharedConnection] setReconnected:^{
        NSLog(@"Connection Reconnected");
    }];
    [[ConnectionStatusConnection sharedConnection] setConnectionSlow:^{
        NSLog(@"Connection Slow");
    }];
    [[ConnectionStatusConnection sharedConnection] setReceived:^(NSString * data){
        NSLog(@"%@",data);
    }];
    [[ConnectionStatusConnection sharedConnection] setError:^(NSError *error){
        NSLog(@"%@",[NSString stringWithFormat:@"Connection Error: %@",error.localizedDescription]);
    }];
    [[ConnectionStatusConnection sharedConnection] setClosed:^(){
        NSLog(@"Connection Closed");
    }];
    
    [[ConnectionStatusConnection sharedConnection] setPongBlock:^{
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        [strongSelf.data insertObject:@"Pong" atIndex:0];
        [strongSelf.tableView reloadData];
    }];
    [[ConnectionStatusConnection sharedConnection] setJoinedBlock:^(NSString *connectionId, NSString *when) {
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        [strongSelf.data insertObject:[NSString stringWithFormat:@"%@ joined at: %@",connectionId,when] atIndex:0];
        [strongSelf.tableView reloadData];
    }];
    [[ConnectionStatusConnection sharedConnection] setRejoinedBlock:^(NSString *connectionId, NSString *when) {
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        [strongSelf.data insertObject:[NSString stringWithFormat:@"%@ rejoined at: %@",connectionId,when] atIndex:0];
        [strongSelf.tableView reloadData];
    }];
    [[ConnectionStatusConnection sharedConnection] setLeaveBlock:^(NSString *connectionId, NSString *when) {
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        [strongSelf.data insertObject:[NSString stringWithFormat:@"%@ left at: %@",connectionId,when] atIndex:0];
        [strongSelf.tableView reloadData];
    }];
    [[ConnectionStatusConnection sharedConnection] start];
}

- (IBAction)ping:(id)sender {
    [[ConnectionStatusConnection sharedConnection] ping];
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
