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
#define kProtocolVersion @"ProtocolVersion"

@end

@implementation SRNegotiationResponse

@synthesize connectionId;
@synthesize url;
@synthesize protocolVersion;

#pragma mark - Initialization

- (id)initWithDictionary:(NSDictionary*)dict
{
	self = [super init];
	if(self != nil)
	{
		connectionId = [dict objectForKey:kConnectionId];
		url = [dict objectForKey:kUrl];
        protocolVersion = [dict objectForKey:kProtocolVersion];
	}
	return self;
}

- (NSString *)description 
{  
    return [NSString stringWithFormat:@"NegotiationResponse: ConnectionId=%@ Url=%@ ProtocolVersion=%@",connectionId,url,protocolVersion];
}

- (void)updateWithDictionary:(NSDictionary *)dict
{
	connectionId = [dict objectForKey:kConnectionId];
	url = [dict objectForKey:kUrl];
    protocolVersion = [dict objectForKey:kProtocolVersion];
}

- (id)proxyForJson
{
    NSMutableDictionary* dict = [[NSMutableDictionary alloc]init];
    if (connectionId) [dict setObject:connectionId forKey:kConnectionId];
    if (url) [dict setObject:url forKey:kUrl];
    if (protocolVersion) [dict setObject:protocolVersion forKey:kProtocolVersion];
    
    return dict;
}

@end
