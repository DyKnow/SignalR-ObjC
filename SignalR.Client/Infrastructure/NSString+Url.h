//
//  NSString+Url.h
//  SignalR
//
//  Created by Alex Billingsley on 11/8/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (UrlAdditions)

+ (NSString*)addQueryStringToUrlString:(NSString *)urlString withDictionary:(NSDictionary *)dictionary;

- (NSString *) urlEncodedString;
- (NSString *) urlDecodedString;

@end
