//
//  StreamingConnectionViewController.m
//  SignalR.Client.ObjC Example
//
//  Created by Alex Billingsley on 3/2/16.
//
//

#import "StreamingConnectionViewController.h"
#import "StreamingConnection.h"

@interface StreamingConnectionViewController ()

@property (strong, nonatomic, readwrite) NSMutableArray *data;

@end

@implementation StreamingConnectionViewController

- (void)viewDidDisappear:(BOOL)animated {
    [[StreamingConnection sharedConnection] stop];
    [super viewDidDisappear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if(_data == nil) {
        _data = [NSMutableArray array];
    }
    
    __weak __typeof(&*self)weakSelf = self;
    [[StreamingConnection sharedConnection] setStarted:^{
        NSLog(@"Connection Opened");
    }];
    [[StreamingConnection sharedConnection] setReconnecting:^{
        NSLog(@"Connection Reconnecting");
    }];
    [[StreamingConnection sharedConnection] setReconnected:^{
        NSLog(@"Connection Reconnected");
    }];
    [[StreamingConnection sharedConnection] setConnectionSlow:^{
        NSLog(@"Connection Slow");
    }];
    [[StreamingConnection sharedConnection] setReceived:^(NSString * data){
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        [strongSelf.data insertObject:data atIndex:0];
        [strongSelf.tableView reloadData];
    }];
    [[StreamingConnection sharedConnection] setError:^(NSError *error){
        NSLog(@"%@",[NSString stringWithFormat:@"Connection Error: %@",error.localizedDescription]);
    }];
    [[StreamingConnection sharedConnection] setClosed:^(){
        NSLog(@"Connection Closed");
    }];
    [[StreamingConnection sharedConnection] start];
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
