//
//  SRNegotiationResponse.m
//  SignalR
//
//  Created by Alex Billingsley on 11/1/11.
//  Copyright (c) 2011 DyKnow LLC. (http://dyknow.com/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
//  documentation files (the "Software"), to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and 
//  to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of 
//  the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
//  THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
//  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
//  DEALINGS IN THE SOFTWARE.
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
