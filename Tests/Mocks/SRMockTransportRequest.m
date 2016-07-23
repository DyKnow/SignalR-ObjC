//
//  SRMockTransportRequest.m
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 7/20/16.
//  Copyright © 2016 DyKnow LLC. All rights reserved.
//

#import "SRMockTransportRequest.h"

@implementation SRMockTransportRequest

- (BOOL)matchesURLRequest:(NSURLRequest *)request {
    return [[[UMKMockURLProtocol canonicalURLForURL:self.URL] path] isEqualToString:[[UMKMockURLProtocol canonicalURLForURL:request.URL] path]] &&
    (request.HTTPMethod && [self.HTTPMethod caseInsensitiveCompare:request.HTTPMethod] == NSOrderedSame);
}

@end
