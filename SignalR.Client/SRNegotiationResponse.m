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

@end

@implementation SRNegotiationResponse

static NSString * const kConnectionId = @"ConnectionId";
static NSString * const kConnectionToken = @"ConnectionToken";
static NSString * const kUrl = @"Url";
static NSString * const kProtocolVersion = @"ProtocolVersion";
static NSString * const kDisconnectTimeout = @"DisconnectTimeout";
static NSString * const kTryWebSockets = @"TryWebSockets";
static NSString * const kKeepAliveTimeout= @"KeepAliveTimeout";
static NSString * const kTransportConnectTimeout= @"TransportConnectTimeout";

- (instancetype)init {
    if (self = [super init]) {
        _connectionId = @"";
        _connectionToken = @"";
		_url = @"";
        _protocolVersion = @"";
        _disconnectTimeout = @0;
        _tryWebSockets = NO;
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary*)dict {
	if (self = [super init]) {
		_connectionId = [NSString stringWithFormat:@"%@",dict[kConnectionId]];
        _connectionToken = dict[kConnectionToken];
		_url = [NSString stringWithFormat:@"%@",dict[kUrl]];
        _protocolVersion = [NSString stringWithFormat:@"%@",dict[kProtocolVersion]];
        _disconnectTimeout = dict[kDisconnectTimeout];
        _tryWebSockets = [[dict objectForKey:kTryWebSockets] boolValue];
        _keepAliveTimeout = dict[kKeepAliveTimeout];
        _transportConnectTimeout = dict[kTransportConnectTimeout];
	}
	return self;
}

@end
