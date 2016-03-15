//
//  ConnectionStatusConnection.h
//  SignalR.Client.ObjC Example
//
//  Created by Alex Billingsley on 3/1/16.
//
//

#import "SignalR.h"

@interface ConnectionStatusConnection : SRHubConnection

+ (instancetype)sharedConnection;

- (void)ping;

- (void)setPongBlock:(void (^)(void))block;
- (void)setJoinedBlock:(void (^)(NSString *connectionId, NSString *when))block;
- (void)setRejoinedBlock:(void (^)(NSString *connectionId, NSString *when))block;
- (void)setLeaveBlock:(void (^)(NSString *connectionId, NSString *when))block;


@end
