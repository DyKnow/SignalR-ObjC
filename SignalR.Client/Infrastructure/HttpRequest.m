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

@synthesize connection = _connection;
@synthesize urlConnection = _urlConnection;
@synthesize receivedData = _receivedData;
@synthesize resultBlock = _resultBlock;

#pragma mark - 
#pragma mark Initialization

+ (HttpRequest *)httpRequest:(SRConnection *)connection URLConnection:(NSURLConnection *)urlConnection block:(void(^)(SRConnection *, id))block
{
    HttpRequest *request = [[HttpRequest alloc] init];
    
    request.connection = connection;
    request.urlConnection = urlConnection;
    request.resultBlock = block;
    
    return request;
}

- (NSMutableData *)receivedData 
{
    if (_receivedData == nil) 
    {
		_receivedData = [[NSMutableData alloc] init];
	}
	return _receivedData;
}

@end
