//
//  HttpRequest.h
//  SignalR
//
//  Created by Alex Billingsley on 10/27/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SRConnection;

typedef void (^onCompletion)(SRConnection *, id);

@interface HttpRequest : NSObject

@property (strong, nonatomic, readwrite) SRConnection *connection;
@property (strong, nonatomic, readwrite) NSURLConnection *urlConnection;
@property (strong, nonatomic, readwrite) NSMutableData *receivedData;
@property (copy) onCompletion resultBlock;

+ (HttpRequest *)httpRequest:(SRConnection *)connection URLConnection:(NSURLConnection *)urlConnection block:(void(^)(SRConnection *, id))block;

@end
