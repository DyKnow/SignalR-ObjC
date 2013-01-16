//
//  SRRequest.h
//  SignalR
//
//  Created by Alex Billingsley on 3/23/12.
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

#import <Foundation/Foundation.h>

@protocol SRRequest <NSObject>

/*
 * The user agent for this request.
 */
@property (strong, nonatomic, readwrite) NSString *userAgent;

/*
 * The timeout interval for the request
 */
@property (assign, nonatomic, readwrite) NSTimeInterval timeoutInterval;

/*
 * The credentials for this request.
 */
@property (strong, nonatomic, readwrite) NSURLCredential *credentials;

/*
 * The headers for this request.
 */
@property (strong, nonatomic, readwrite) NSMutableDictionary *headers;

/*
 * Gets of sets proxy information for the connection.
 */
//@property (strong, nonatomic, readwrite) id proxy; TODO: Add the proxy information??

/*
 * The accept header for this request.
 */
@property (strong, nonatomic, readwrite) NSString * accept;

/*
 * Aborts the request.
 */
- (void)abort;

@end
