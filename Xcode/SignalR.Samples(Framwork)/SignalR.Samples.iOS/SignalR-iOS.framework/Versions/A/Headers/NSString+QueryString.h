//
//  NSString+QueryString.h
//  SignalR
//
//  Created by Alex Billingsley on 10/18/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

@interface NSString (QueryString)

- (NSString*)stringByEscapingForURLQuery;
- (NSString*)stringByUnescapingFromURLQuery;

@end
