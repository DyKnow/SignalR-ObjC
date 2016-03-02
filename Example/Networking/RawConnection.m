//
//  RawConnection.m
//  SignalR.Client.ObjC Example
//
//  Created by Alex Billingsley on 3/1/16.
//
//

#import "RawConnection.h"

typedef enum {
    SRMessageTypeSend = 0,
    SRMessageTypeBroadcast,
    SRMessageTypeJoin,
    SRMessageTypePrivateMessage,
    SRMessageTypeAddToGroup,
    SRMessageTypeRemoveFromGroup,
    SRMessageTypeSendToGroup,
    SRMessageTypeBroadcastExceptMe
} SRMessageType;

static NSString * const SRConnectionBaseURLString = @"http://abill-win10:9090/";

@implementation RawConnection

+ (instancetype)sharedConnection {
    static RawConnection *_sharedConnection = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedConnection = [[RawConnection alloc] initWithURLString:[SRConnectionBaseURLString stringByAppendingFormat:@"raw-connection"]];
    });
    
    return _sharedConnection;
}

- (void)sendMessage:(NSString *)message completionHandler:(void (^)(id response, NSError *error))block; {
    id json = @{
        @"type": @(SRMessageTypeSend),
        @"value": message
    };
    [self send:json completionHandler:block];
}

- (void)broadcastMessage:(NSString *)message completionHandler:(void (^)(id response, NSError *error))block; {
    id json = @{
        @"type": @(SRMessageTypeBroadcast),
        @"value": message
    };
    [self send:json completionHandler:block];
}

- (void)broadcastMessageExceptMe:(NSString *)message completionHandler:(void (^)(id response, NSError *error))block {
    id json = @{
        @"type": @(SRMessageTypeBroadcastExceptMe),
        @"value": message
    };
    [self send:json completionHandler:block];
}

- (void)join:(NSString *)username completionHandler:(void (^)(id response, NSError *error))block; {
    id json = @{
        @"type": @(SRMessageTypeJoin),
        @"value": username
    };
    [self send:json completionHandler:block];
}

- (void)sendMessage:(NSString *)message toUser:(NSString *)username completionHandler:(void (^)(id response, NSError *error))block; {
    id json = @{
        @"type": @(SRMessageTypePrivateMessage),
        @"value": [NSString stringWithFormat:@"%@|%@",username, message]
    };
    [self send:json completionHandler:block];
}

- (void)joinGroup:(NSString *)group completionHandler:(void (^)(id response, NSError *error))block; {
    id json = @{
        @"type": @(SRMessageTypeAddToGroup),
        @"value": group
    };
    [self send:json completionHandler:block];
}

- (void)sendMessage:(NSString *)message toGroup:(NSString *)group completionHandler:(void (^)(id response, NSError *error))block; {
    id json = @{
        @"type": @(SRMessageTypeSendToGroup),
        @"value": [NSString stringWithFormat:@"%@|%@",group, message]
    };
    [self send:json completionHandler:block];
}

- (void)leaveGroup:(NSString *)group completionHandler:(void (^)(id response, NSError *error))block {
    id json = @{
        @"type": @(SRMessageTypeRemoveFromGroup),
        @"value": group
    };
    [self send:json completionHandler:block];
}

@end
