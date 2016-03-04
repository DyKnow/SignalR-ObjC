//
//  DrawingPadConnection.h
//  SignalR.Client.ObjC Example
//
//  Created by Alex Billingsley on 3/3/16.
//
//

#import "SignalR.h"

@interface DrawingPadConnection : SRHubConnection

+ (instancetype)sharedConnection;

- (void)join;
- (void)draw:(NSString *)line completionHandler:(void (^)(id response, NSError *error))block;

- (void)setDrawBlock:(void (^)(NSDictionary *json))block;

@end
