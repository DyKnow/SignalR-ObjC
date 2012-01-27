//
//  SRHttpResponse.h
//  SignalR.Samples
//
//  Created by Alex Billingsley on 1/27/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SRHttpResponse : NSObject 

@property (strong, nonatomic, readwrite) NSURLRequest *urlRequest;
@property (strong, nonatomic, readwrite) NSURLResponse *urlResponse;
@property (strong, nonatomic, readwrite) id response;

@end
