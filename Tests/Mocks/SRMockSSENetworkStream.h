//
//  SRMockSSENetworkStream.h
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 3/15/16.
//  Copyright © 2016 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

@interface SRMockSSENetworkStream : NSObject

- (void)prepareForOpeningResponse:(void (^)())then;
- (void)prepareForOpeningResponse:(NSString *)response then:(void (^)())then;
- (void)prepareForNextResponse:(NSString *)response then:(void (^)())then;
- (void)prepareForClose;
- (void)prepareForError:(NSError *)error;

- (void)stopMocking;

@end
