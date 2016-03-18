//
//  ConnectionStatusConnection.m
//  SignalR.Client.ObjC Example
//
//  Created by Alex Billingsley on 3/1/16.
//
//

#import "ConnectionStatusConnection.h"

static NSString * const SRConnectionBaseURLString = @"http://abill-win10:9090/";

typedef void (^SRPongBlock)();
typedef void (^SRConnectionStatusBlock)(NSString *connectionId, NSString *when);

@interface ConnectionStatusConnection ()

@property (strong, nonatomic, readwrite) SRHubProxy * hub;

@property (readwrite, nonatomic, copy) SRPongBlock pong;
@property (readwrite, nonatomic, copy) SRConnectionStatusBlock joined;
@property (readwrite, nonatomic, copy) SRConnectionStatusBlock rejoined;
@property (readwrite, nonatomic, copy) SRConnectionStatusBlock leave;

@end

@implementation ConnectionStatusConnection

+ (instancetype)sharedConnection {
    static ConnectionStatusConnection *_sharedConnection = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedConnection = [[ConnectionStatusConnection alloc] initWithURLString:SRConnectionBaseURLString];
    });
    
    return _sharedConnection;
}

- (instancetype)initWithURLString:(NSString *)url {
    self = [super initWithURLString:url];
    if (!self) {
        return nil;
    }
    
    _hub = [self createHubProxy:@"statushub"];
    [_hub on:@"pong" perform:self selector:@selector(handlePong)];
    [_hub on:@"joined" perform:self selector:@selector(handleJoined:when:)];
    [_hub on:@"rejoined" perform:self selector:@selector(handleRejoined:when:)];
    [_hub on:@"leave" perform:self selector:@selector(handleLeave:when:)];

    return self;
}

- (void)ping {
    [self.hub invoke:@"ping" withArgs:@[] completionHandler:nil];
}

- (void)setPongBlock:(void (^)(void))block {
    self.pong = block;
}

- (void)setJoinedBlock:(void (^)(NSString *connectionId, NSString *when))block; {
    self.joined = block;
}

- (void)setRejoinedBlock:(void (^)(NSString *connectionId, NSString *when))block; {
    self.rejoined = block;
}

- (void)setLeaveBlock:(void (^)(NSString *connectionId, NSString *when))block; {
    self.leave = block;
}

#pragma mark -
#pragma mark Private

- (void)handlePong {
    if(self.pong) {
        self.pong();
    }
}

- (void)handleJoined:(NSString *)connectionId when:(NSString *)when {
    if(self.joined) {
        self.joined(connectionId,when);
    }
}

- (void)handleRejoined:(NSString *)connectionId when:(NSString *)when {
    if(self.rejoined) {
        self.rejoined(connectionId,when);
    }
}

- (void)handleLeave:(NSString *)connectionId when:(NSString *)when {
    if(self.leave) {
        self.leave(connectionId,when);
    }
}

@end
