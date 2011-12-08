//
//  HttpHelper.m
//  SignalR
//
//  Created by Alex Billingsley on 10/18/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "HttpHelper.h"

#import "SBJson.h"

@interface HttpHelper()

- (void)postInternal:(SRConnection *)connection url:(NSString *)url requestPreparer:(void(^)(NSMutableURLRequest *))requestPreparer postData:(NSDictionary *)postData onCompletion:(void(^)(SRConnection *, id))block;

@end

static HttpHelper *sharedHttpRequestManager = nil;

@implementation HttpHelper

@synthesize requests;

#pragma mark - Initialization

+ (HttpHelper *)sharedHttpRequestManager {
	if (sharedHttpRequestManager == nil) {
		sharedHttpRequestManager = [[HttpHelper alloc] init];
	}
	return sharedHttpRequestManager;
}

#pragma mark - Request Management

- (NSMutableDictionary *)requests 
{
	if (requests == nil) 
    {
		requests = [[NSMutableDictionary alloc] init];
	}
	return requests;
}

#pragma mark - URLConnection

- (void)postAsync:(SRConnection *)connection url:(NSString *)url onCompletion:(void(^)(SRConnection *, id))block
{
    [self postInternal:connection url:url requestPreparer:nil postData:[[NSDictionary alloc] init] onCompletion:block];
}

- (void)postAsync:(SRConnection *)connection url:(NSString *)url requestPreparer:(void(^)(NSMutableURLRequest *))requestPreparer onCompletion:(void(^)(SRConnection *, id))block
{
    [self postInternal:connection url:url requestPreparer:requestPreparer postData:[[NSDictionary alloc] init] onCompletion:block];
}

- (void)postAsync:(SRConnection *)connection url:(NSString *)url requestPreparer:(void(^)(NSMutableURLRequest *))requestPreparer postData:(NSDictionary *)postData onCompletion:(void(^)(SRConnection *, id))block
{
    [self postInternal:connection url:url requestPreparer:requestPreparer postData:postData onCompletion:block];
}

- (void)postInternal:(SRConnection *)connection url:(NSString *)url requestPreparer:(void(^)(NSMutableURLRequest *))requestPreparer postData:(NSDictionary *)postData onCompletion:(void(^)(SRConnection *, id))block
{
    NSString *sb = @"";
    
    NSArray *keyArray =  [postData allKeys];
    int count = [keyArray count];
    for (int i=0; i < count; i++) {
        if(sb.length > 0){
            sb = [sb stringByAppendingString:@"&"];
        }
        id object = [postData objectForKey:[keyArray objectAtIndex:i]];
        NSString *objectAsString = @"";
        if([object isKindOfClass:[NSString class]])
        {
            objectAsString = object;
        }
        else
        {
            NSString *json = [[SBJsonWriter new] stringWithObject:object];
            objectAsString = [json urlEncodedString];
        }
        
        sb = [sb stringByAppendingFormat:@"%@=%@",[keyArray objectAtIndex:i],objectAsString];
    } 
    
    NSData *requestData = [sb dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20];
    
    if(requestPreparer != nil)
    {
        requestPreparer(request);
    }
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%d", [requestData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody: requestData];
    
    NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    if (!urlConnection) {
        [NSException raise:@"NullException" format:@"Connection failed to initialize"];
    }
    else
    {
        [self.requests setObject:[HttpRequest httpRequest:connection URLConnection:urlConnection block:block] 
                          forKey:[NSNumber numberWithInt:(int)urlConnection]];
    }
}

#pragma mark - NSURLConnection Delegate

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse 
{
	return request;
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace 
{
	return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge 
{    
	[challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
	[challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response 
{

}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data 
{
    HttpRequest *httpRequest = [self.requests objectForKey:[NSNumber numberWithInt:(int)connection]];
	if (httpRequest != nil) {
        if (data != nil) {
			[httpRequest.receivedData appendData:data];
		}
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection 
{
    HttpRequest *httpRequest = [self.requests objectForKey:[NSNumber numberWithInt:(int)connection]];
	if (httpRequest != nil) {
        if(httpRequest.resultBlock)
        {
            NSString *JSONString = [[NSString alloc] initWithData:httpRequest.receivedData encoding:NSASCIIStringEncoding];
            httpRequest.resultBlock(httpRequest.connection,JSONString);
        }
        [self.requests removeObjectForKey:[NSNumber numberWithInt:(int)connection]];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error 
{
    HttpRequest *httpRequest = [self.requests objectForKey:[NSNumber numberWithInt:(int)connection]];
	if (httpRequest != nil) {
        if(httpRequest.resultBlock)
        {
            httpRequest.resultBlock(httpRequest.connection,error);
        }
        [self.requests removeObjectForKey:[NSNumber numberWithInt:(int)connection]];
    }
}

@end
