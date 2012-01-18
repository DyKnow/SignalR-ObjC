//
//  Router.h
//  SignalR
//
//  Created by Alex Billingsley on 1/11/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Router : NSObject

@property (strong, nonatomic, readonly) NSString *server_url;

+ (Router *)sharedRouter;

@end
