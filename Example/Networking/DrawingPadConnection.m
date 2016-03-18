//
//  DrawingPadConnection.m
//  SignalR.Client.ObjC Example
//
//  Created by Alex Billingsley on 3/3/16.
//
//

#import "DrawingPadConnection.h"

static NSString * const SRConnectionBaseURLString = @"http://abill-win10:9090/";

typedef void (^SRConnectionDrawBlock)(NSDictionary *json);

@interface DrawingPadConnection ()

@property (strong, nonatomic, readwrite) SRHubProxy * hub;

@property (readwrite, nonatomic, copy) SRConnectionDrawBlock draw;

@end

@implementation DrawingPadConnection

+ (instancetype)sharedConnection {
    static DrawingPadConnection *_sharedConnection = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedConnection = [[DrawingPadConnection alloc] initWithURLString:SRConnectionBaseURLString];
    });
    
    return _sharedConnection;
}

- (instancetype)initWithURLString:(NSString *)url {
    self = [super initWithURLString:url];
    if (!self) {
        return nil;
    }
    
    _hub = [self createHubProxy:@"DrawingPad"];
    [_hub on:@"draw" perform:self selector:@selector(handleDraw:)];
    
    return self;
}

- (void)join {
    [_hub invoke:@"join" withArgs:@[] completionHandler:nil];
}

- (void)draw:(NSString *)line completionHandler:(void (^)(id response, NSError *error))block; {
    [_hub invoke:@"draw" withArgs:@[line] completionHandler:block];
}

- (void)setDrawBlock:(void (^)(NSDictionary *json))block {
    self.draw = block;
}

- (void)handleDraw:(NSDictionary *)json {
    if(self.draw) {
        self.draw(json);
    }
}

@end
