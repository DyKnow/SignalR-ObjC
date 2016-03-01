//
//  ViewController.m
//  OS X Example
//
//  Created by Alex Billingsley on 2/29/16.
//
//

#import "ViewController.h"
#import "SignalR.h"

@interface ViewController ()

@property (strong, nonatomic, readwrite) SRConnection *connection;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _connection = [SRConnection connectionWithURLString:[@"http://myserver.com" stringByAppendingFormat:@"streaming-connection"]];
    [self.connection setStarted:^{
        NSLog(@"Connection Opened");
    }];
    [self.connection setReconnecting:^{
        NSLog(@"Connection Reconnecting");
    }];
    [self.connection setReconnected:^{
        NSLog(@"Connection Reconnected");
    }];
    [self.connection setConnectionSlow:^{
        NSLog(@"Connection Slow");
    }];
    [self.connection setReceived:^(NSString * data){
        NSLog(@"%@",data);
    }];
    [self.connection setError:^(NSError *error){
        NSLog(@"%@",[NSString stringWithFormat:@"Connection Error: %@",error.localizedDescription]);
    }];
    [self.connection setClosed:^(){
        NSLog(@"Connection Closed");
    }];
    [self.connection start];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

@end
