//
//  MouseTrackingConnection.m
//  SignalR.Client.ObjC Example
//
//  Created by Alex Billingsley on 3/2/16.
//
//

#import "MouseTrackingConnection.h"

static NSString * const SRConnectionBaseURLString = @"http://abill-win10:9090/";

typedef void (^SRConnectionMouseMoveBlock)(NSString *connectionId, NSNumber *x, NSNumber *y);

@interface MouseTrackingConnection ()

@property (strong, nonatomic, readwrite) SRHubProxy * hub;

@property (readwrite, nonatomic, copy) SRConnectionMouseMoveBlock move;

@end

@implementation MouseTrackingConnection

+ (instancetype)sharedConnection {
    static MouseTrackingConnection *_sharedConnection = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedConnection = [[MouseTrackingConnection alloc] initWithURLString:SRConnectionBaseURLString];
    });
    
    return _sharedConnection;
}

- (instancetype)initWithURLString:(NSString *)url {
    self = [super initWithURLString:url];
    if (!self) {
        return nil;
    }
    
    _hub = [self createHubProxy:@"MouseTracking"];
    [_hub on:@"move" perform:self selector:@selector(handleMove:x:y:)];
    
    return self;
}

- (void)join {
    [_hub invoke:@"join" withArgs:@[] completionHandler:nil];
}

- (void)move:(CGPoint)point completionHandler:(void (^)(id response, NSError *error))block; {
    [_hub invoke:@"move" withArgs:@[@(point.x), @(point.y)] completionHandler:block];
}

- (void)setMoveBlock:(void (^)(NSString *connectionId, NSNumber *x, NSNumber *y))block {
    self.move = block;
}

- (void)handleMove:(NSString *)connectionId x:(NSNumber *)x y:(NSNumber *)y {
    if(self.move) {
        self.move(connectionId,x,y);
    }
}

@end
