//
//  StreamingConnection.m
//  SignalR.Client.ObjC Example
//
//  Created by Alex Billingsley on 3/1/16.
//
//

#import "StreamingConnection.h"

static NSString * const SRConnectionBaseURLString = @"http://abill-win10:9090/";

@implementation StreamingConnection

+ (instancetype)sharedConnection {
    static StreamingConnection *_sharedConnection = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedConnection = [[StreamingConnection alloc] initWithURLString:[SRConnectionBaseURLString stringByAppendingFormat:@"streaming-connection"]];
    });
    
    return _sharedConnection;
}

@end
