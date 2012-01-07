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

@synthesize connectionId = _connectionId;
@synthesize url = _url;
@synthesize protocolVersion = _protocolVersion;

#pragma mark - Initialization

- (id) init
{
    if (self = [super init])
    {
        _connectionId = [NSString stringWithFormat:@""];
		_url = [NSString stringWithFormat:@""];
        _protocolVersion = [NSString stringWithFormat:@""];
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary*)dict
{
	self = [self init];
	if(self != nil)
	{
		_connectionId = [dict objectForKey:kConnectionId];
		_url = [dict objectForKey:kUrl];
        _protocolVersion = [dict objectForKey:kProtocolVersion];
	}
	return self;
}

- (void)updateWithDictionary:(NSDictionary *)dict
{
	_connectionId = [dict objectForKey:kConnectionId];
	_url = [dict objectForKey:kUrl];
    _protocolVersion = [dict objectForKey:kProtocolVersion];
}

- (id)proxyForJson
{
    NSMutableDictionary* dict = [[NSMutableDictionary alloc]init];
    [dict setObject:[NSString stringWithFormat:@"%@",_connectionId] forKey:kConnectionId];
    [dict setObject:[NSString stringWithFormat:@"%@",_url] forKey:kUrl];
    [dict setObject:[NSString stringWithFormat:@"%@",_protocolVersion] forKey:kProtocolVersion];
    
    return dict;
}

- (NSString *)description 
{  
    return [NSString stringWithFormat:@"NegotiationResponse: ConnectionId=%@ Url=%@ ProtocolVersion=%@",_connectionId,_url,_protocolVersion];
}
@end
