//
//  SRNegotiationResponse.m
//  SignalR
//
//  Created by Alex Billingsley on 11/1/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "SRNegotiationResponse.h"

@interface SRNegotiationResponse ()

#define kConnectionId @"ConnectionId"
#define kUrl @"Url"
#define kProtocolVersion @"ProtocolVersion"

@end

@implementation SRNegotiationResponse

@synthesize connectionId = _connectionId;
@synthesize url = _url;
@synthesize protocolVersion = _protocolVersion;

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
	if (self = [super init]) 
    {
		_connectionId = [NSString stringWithFormat:@"%@",[dict objectForKey:kConnectionId]];
		_url = [NSString stringWithFormat:@"%@",[dict objectForKey:kUrl]];
        _protocolVersion = [NSString stringWithFormat:@"%@",[dict objectForKey:kProtocolVersion]];
	}
	return self;
}

- (void)updateWithDictionary:(NSDictionary *)dict
{
    _connectionId = ([dict objectForKey:kConnectionId]) ? [NSString stringWithFormat:@"%@",[dict objectForKey:kConnectionId]] : _connectionId;
    _url = ([dict objectForKey:kUrl]) ? [NSString stringWithFormat:@"%@",[dict objectForKey:kUrl]] : _url;
    _protocolVersion = ([dict objectForKey:kProtocolVersion]) ? [NSString stringWithFormat:@"%@",[dict objectForKey:kProtocolVersion]] : _protocolVersion;
}

- (id)proxyForJson
{
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    
    [dict setObject:[NSString stringWithFormat:@"%@",_connectionId] forKey:kConnectionId];
    [dict setObject:[NSString stringWithFormat:@"%@",_url] forKey:kUrl];
    [dict setObject:[NSString stringWithFormat:@"%@",_protocolVersion] forKey:kProtocolVersion];
    
    return dict;
}

- (NSString *)description 
{  
    return [NSString stringWithFormat:@"NegotiationResponse: ConnectionId=%@ Url=%@ ProtocolVersion=%@",_connectionId,_url,_protocolVersion];
}

- (void)dealloc
{
    _connectionId = nil;
    _url = nil;
    _protocolVersion = nil;
}

@end
