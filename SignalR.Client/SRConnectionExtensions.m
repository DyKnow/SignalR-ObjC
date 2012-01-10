//
//  SRConnectionExtensions.m
//  SignalR
//
//  Created by Alex Billingsley on 1/7/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import "SRConnectionExtensions.h"

@implementation SRConnection (Extensions)

- (id)getValue:(NSString *)key
{
    id value = nil;
    value = [self.items objectForKey:key];
    
    return value;
}

@end
