//
//  DrawingPadViewController.m
//  SignalR.Client.ObjC Example
//
//  Created by Alex Billingsley on 3/3/16.
//
//

#import "DrawingPadViewController.h"
#import "DrawingPadConnection.h"

@interface DrawingPadViewController ()

@property (strong, nonatomic, readwrite) NSMutableArray *data;

@end

@implementation DrawingPadViewController

- (void)viewDidDisappear:(BOOL)animated {
    [[DrawingPadConnection sharedConnection] stop];
    [super viewDidDisappear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if(_data == nil) {
        _data = [NSMutableArray array];
    }
    
    __weak __typeof(&*self)weakSelf = self;
    [[DrawingPadConnection sharedConnection] setStarted:^{
        NSLog(@"Connection Opened");
        [[DrawingPadConnection sharedConnection] join];
    }];
    [[DrawingPadConnection sharedConnection] setReconnecting:^{
        NSLog(@"Connection Reconnecting");
    }];
    [[DrawingPadConnection sharedConnection] setReconnected:^{
        NSLog(@"Connection Reconnected");
    }];
    [[DrawingPadConnection sharedConnection] setConnectionSlow:^{
        NSLog(@"Connection Slow");
    }];
    [[DrawingPadConnection sharedConnection] setReceived:^(NSString * data){
        NSLog(@"%@",data);
    }];
    [[DrawingPadConnection sharedConnection] setError:^(NSError *error){
        NSLog(@"%@",[NSString stringWithFormat:@"Connection Error: %@",error.localizedDescription]);
    }];
    [[DrawingPadConnection sharedConnection] setClosed:^(){
        NSLog(@"Connection Closed");
    }];
    [[DrawingPadConnection sharedConnection] setDrawBlock:^(NSDictionary *json) {
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json
                                                           options:0
                                                             error:&error];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        [strongSelf.data insertObject:[NSString stringWithFormat:@"%@",jsonString] atIndex:0];
        [strongSelf.tableView reloadData];
    }];
    [[DrawingPadConnection sharedConnection] start];
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
