//
//  MouseTrackingConnection.h
//  SignalR.Client.ObjC Example
//
//  Created by Alex Billingsley on 3/2/16.
//
//

#import "SignalR.h"

@interface MouseTrackingConnection : SRHubConnection

+ (instancetype)sharedConnection;

- (void)join;
- (void)move:(CGPoint)point completionHandler:(void (^)(id response, NSError *error))block;

- (void)setMoveBlock:(void (^)(NSString *connectionId, NSNumber *x, NSNumber *y))block;

@end
