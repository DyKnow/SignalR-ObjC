//
//  Router.m
//  SignalR
//
//  Created by Alex Billingsley on 1/11/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import "Router.h"

@interface Router()

@end

@implementation Router

+ (Router *)sharedRouter {
    static Router *_sharedRouter = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedRouter = [[self alloc] init];
    });
    
    return _sharedRouter;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        #warning Set your server location here.
        _server_url = @"http://abill-win81:9000/";
    }
    return self;
}

@end
