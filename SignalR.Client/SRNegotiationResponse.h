//
//  SRNegotiationResponse.h
//  SignalR
//
//  Created by Alex Billingsley on 11/1/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SRNegotiationResponse : NSObject

@property (nonatomic, strong) NSString *connectionId;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *protocolVersion;

- (id)initWithDictionary:(NSDictionary*)dict;
- (void)updateWithDictionary:(NSDictionary *)dict;
- (id) proxyForJson;

@end
