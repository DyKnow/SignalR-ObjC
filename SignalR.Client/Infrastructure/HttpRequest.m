//
//  HttpRequest.m
//  SignalR
//
//  Created by Alex Billingsley on 10/27/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "HttpRequest.h"
#import "SRConnection.h"

@implementation HttpRequest

@synthesize connection;
@synthesize urlConnection;
@synthesize receivedData;
@synthesize resultBlock;

#pragma mark - Initialization

+ (HttpRequest *)httpRequest:(SRConnection *)connection URLConnection:(NSURLConnection *)urlConnection block:(void(^)(SRConnection *, id))block
{
    HttpRequest *request = [[HttpRequest alloc] init];
    
    request.connection = connection;
    request.urlConnection = urlConnection;
    request.resultBlock = block;
    
    return request;
}

- (NSMutableData *)receivedData {
    if (receivedData == nil) {
		receivedData = [[NSMutableData alloc] init];
	}
	return receivedData;
}

@end
