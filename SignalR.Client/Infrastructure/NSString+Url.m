//
//  NSString+Url.m
//  SignalR
//
//  Created by Alex Billingsley on 11/8/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import "NSString+Url.h"

#import "SBJson.h"

@implementation NSString (UrlAdditions)

+(NSString*)addQueryStringToUrlString:(NSString *)urlString withDictionary:(NSDictionary *)dictionary
{
    NSMutableString *urlWithQuerystring = [[NSMutableString alloc] initWithString:urlString];
        
    for (id key in dictionary) {
        NSString *keyString = [key description];
        id object = [dictionary objectForKey:key];
        NSString *valueString = @"";
        
        if([object isKindOfClass:[NSString class]])
        {
            valueString = [[dictionary objectForKey:key] description];
        }
        else
        {
            valueString = [[SBJsonWriter new] stringWithObject:object];
        }
        
        if ([urlWithQuerystring rangeOfString:@"?"].location == NSNotFound) {
            [urlWithQuerystring appendFormat:@"?%@=%@", [keyString urlEncodedString], [valueString urlEncodedString]];
        } else {
            [urlWithQuerystring appendFormat:@"&%@=%@", [keyString urlEncodedString], [valueString urlEncodedString]];
        }
    }
    return urlWithQuerystring;
}

- (NSString *) urlEncodedString
{
    NSArray *escapeChars = [NSArray arrayWithObjects:@";" , @"/" , @"?" , @":" ,
                            @"@" , @"&" , @"=" , @"+" ,
                            @"$" , @"," , @"[" , @"]",
                            @"#", @"!", @"'", @"(", 
                            @")", @"*", @"{", @"}", @"\"", nil];
    
    NSArray *replaceChars = [NSArray arrayWithObjects:@"%3B" , @"%2F" , @"%3F" ,
                             @"%3A" , @"%40" , @"%26" ,
                             @"%3D" , @"%2B" , @"%24" ,
                             @"%2C" , @"%5B" , @"%5D", 
                             @"%23", @"%21", @"%27",
                             @"%28", @"%29", @"%2A",@"%7B", @"%7D", @"%22", nil];
    
    int len = [escapeChars count];
    
    NSMutableString *temp = [self mutableCopy];
    
    int i;
    for(i = 0; i < len; i++)
    {
        
        [temp replaceOccurrencesOfString: [escapeChars objectAtIndex:i]
                              withString:[replaceChars objectAtIndex:i]
                                 options:NSLiteralSearch
                                   range:NSMakeRange(0, [temp length])];
    }
    
    return [NSString stringWithString: temp];
}

-(NSString *)urlDecodedString 
{
    return [self stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

@end
