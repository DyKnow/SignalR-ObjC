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
{
    SRConnection *connection;
    NSURLConnection *urlConnection;
    NSMutableData *receivedData;
    onCompletion resultBlock;
    
}

@property (nonatomic, strong) SRConnection *connection;
@property (nonatomic, strong) NSURLConnection *urlConnection;
@property (nonatomic, strong) NSMutableData *receivedData;
@property (copy) onCompletion resultBlock;

+ (HttpRequest *)httpRequest:(SRConnection *)connection URLConnection:(NSURLConnection *)urlConnection block:(void(^)(SRConnection *, id))block;

@end
