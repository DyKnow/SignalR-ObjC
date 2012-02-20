//
//  SRNegotiationResponse.h
//  SignalR
//
//  Created by Alex Billingsley on 11/1/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SRNegotiationResponse : NSObject

@property (strong, nonatomic, readonly) NSString *connectionId;
@property (strong, nonatomic, readonly) NSString *url;
@property (strong, nonatomic, readonly) NSString *protocolVersion;

- (id)initWithDictionary:(NSDictionary*)dict;
- (void)updateWithDictionary:(NSDictionary *)dict;
- (id)proxyForJson;

@end
