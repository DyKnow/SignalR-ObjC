//
//  SRMockWSNetworkStream.h
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 3/15/16.
//  Copyright © 2016 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
@class SRMockWaitBlockOperation;

@interface SRMockWSNetworkStream : NSObject

@property (strong, nonatomic, readonly) OCMockObject * stream;

- (void)prepareForConnectTimeout:(NSInteger)timeout beforeCaptureTimeout:(void (^)(SRMockWaitBlockOperation *transportConnectTimeout))beforeCaptureTimeout afterCaptureTimeout:(void (^)(SRMockWaitBlockOperation *transportConnectTimeout))afterCaptureTimeout;
- (void)prepareForOpeningResponse:(void (^)())then;
- (void)prepareForOpeningResponse:(NSString *)response then:(void (^)())then;
- (void)prepareForNextResponse:(NSString *)response then:(void (^)())then;
- (void)prepareForError:(NSError *)error;

- (void)stopMocking;

@end
