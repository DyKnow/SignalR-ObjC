//
//  RawConnection.h
//  SignalR.Client.ObjC Example
//
//  Created by Alex Billingsley on 3/1/16.
//
//

#import "SignalR.h"

@interface RawConnection : SRConnection

+ (instancetype)sharedConnection;

- (void)sendMessage:(NSString *)message completionHandler:(void (^)(id response, NSError *error))block;
- (void)broadcastMessage:(NSString *)message completionHandler:(void (^)(id response, NSError *error))block;
- (void)broadcastMessageExceptMe:(NSString *)message completionHandler:(void (^)(id response, NSError *error))block;

- (void)join:(NSString *)username completionHandler:(void (^)(id response, NSError *error))block;
- (void)sendMessage:(NSString *)message toUser:(NSString *)username completionHandler:(void (^)(id response, NSError *error))block;

- (void)joinGroup:(NSString *)group completionHandler:(void (^)(id response, NSError *error))block;
- (void)sendMessage:(NSString *)message toGroup:(NSString *)group completionHandler:(void (^)(id response, NSError *error))block;
- (void)leaveGroup:(NSString *)group completionHandler:(void (^)(id response, NSError *error))block;

@end
