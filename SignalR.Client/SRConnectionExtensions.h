//
//  SRConnectionExtensions.h
//  SignalR
//
//  Created by Alex Billingsley on 1/7/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRConnection.h"

@interface SRConnection (Extensions)

- (id)getValue:(NSString *)key;

@end
