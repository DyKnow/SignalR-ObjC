//
//  ViewController.m
//  OS X Example
//
//  Created by Alex Billingsley on 2/29/16.
//
//

#import "ViewController.h"
#import "StreamingConnection.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

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
        NSLog(@"%@",data);
    }];
    [[StreamingConnection sharedConnection] setError:^(NSError *error){
        NSLog(@"%@",[NSString stringWithFormat:@"Connection Error: %@",error.localizedDescription]);
    }];
    [[StreamingConnection sharedConnection] setClosed:^(){
        NSLog(@"Connection Closed");
    }];
    [[StreamingConnection sharedConnection] start];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

@end
