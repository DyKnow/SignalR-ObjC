//
//  SRNegotiationResponse.m
//  SignalR
//
//  Created by Alex Billingsley on 11/1/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "SRNegotiationResponse.h"

@interface SRNegotiationResponse()

#define kConnectionId @"ConnectionId"
#define kUrl @"Url"

@end

@implementation SRNegotiationResponse

@synthesize connectionId;
@synthesize url;

#pragma mark - Initialization

- (id)initWithDictionary:(NSDictionary*)dict
{
	self = [super init];
	if(self != nil)
	{
		connectionId = [dict objectForKey:kConnectionId];
		url = [dict objectForKey:kUrl];
	}
	return self;
}

- (NSString *)description 
{  
    return [NSString stringWithFormat:@"NegotiationResponse: ConnectionId=%@ Url=%@",connectionId,url];
}

- (void)updateWithDictionary:(NSDictionary *)dict
{
	connectionId = [dict objectForKey:kConnectionId];
	url = [dict objectForKey:kUrl];
}

- (id)proxyForJson
{
    NSMutableDictionary* dict = [[NSMutableDictionary alloc]init];
    if (connectionId) [dict setObject:connectionId forKey:kConnectionId];
    if (url) [dict setObject:url forKey:kUrl];
    
    return dict;
}

@end
