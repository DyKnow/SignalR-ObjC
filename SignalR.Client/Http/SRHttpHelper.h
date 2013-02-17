//
//  SRHttpHelper.h
//  SignalR
//
//  Created by Alex Billingsley on 10/18/11.
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

typedef void (^SRPrepareRequestBlock)(id request);
typedef void (^SRCompletionHandler)(id response);

/**
 * `SRHttpHelper` defines a protocol used to create HttpRequest objects that are configured for the various http request methods (GET, PUT etc)
 */
@protocol SRHttpHelper <NSObject>

#pragma mark -
#pragma mark GET Requests

///-------------------------------
/// @name GET Requests
///-------------------------------

/**
 * Creates a GET request with the specified url returns on the given block
 * 
 * @param url The url relative to the server endpoint
 * @param block A function to be called when the post finishes. The block should handle both SUCCESS and FAILURE
 */
+ (void)getAsync:(NSString *)url completionHandler:(SRCompletionHandler)block;

/**
 * Creates a GET request with the specified url returns on the given block
 *
 * @param url The url relative to the server endpoint
 * @param requestPreparer A function to be called on the NSMutableURLRequest created for the request
 * This can be used to modify properties of the POST, for example timeout or cache protocol
 * @param block A function to be called when the post finishes. The block should handle both SUCCESS and FAILURE
 */
+ (void)getAsync:(NSString *)url requestPreparer:(SRPrepareRequestBlock)requestPreparer completionHandler:(SRCompletionHandler)block;

/**
 * Creates a GET request with the specified url returns on the given block
 *
 * @param url The url relative to the server endpoint
 * @param parameters An Object that conforms to SRSerializable to pass as parameters to the endpoint
 * This can be used to modify properties of the POST, for example timeout or cache protocol
 * @param block A function to be called when the post finishes. The block should handle both SUCCESS and FAILURE
 */
+ (void)getAsync:(NSString *)url parameters:(id)parameters completionHandler:(SRCompletionHandler)block;

/**
 * Creates a GET request with the specified url returns on the given block
 *
 * @param url The url relative to the server endpoint
 * @param parameters An Object that conforms to SRSerializable to pass as parameters to the endpoint
 * @param requestPreparer A function to be called on the NSMutableURLRequest created for the request
 * This can be used to modify properties of the POST, for example timeout or cache protocol
 * @param block A function to be called when the post finishes. The block should handle both SUCCESS and FAILURE
 */
+ (void)getAsync:(NSString *)url requestPreparer:(SRPrepareRequestBlock)requestPreparer parameters:(id)parameters completionHandler:(SRCompletionHandler)block;

#pragma mark -
#pragma mark POST Requests

///-------------------------------
/// @name POST Requests
///-------------------------------

/**
 * Creates a POST request with the specified url returns on the given block
 * This POST will contain no payload
 * 
 * @param url The url relative to the server endpoint
 * @param block A function to be called when the post finishes. The block should handle both SUCCESS and FAILURE
 */
+ (void)postAsync:(NSString *)url completionHandler:(SRCompletionHandler)block;

/**
 * Creates a POST request with the specified url returns on the given block
 * This POST will contain no payload
 *
 * @param url The url relative to the server endpoint
 * @param requestPreparer A function to be called on the NSMutableURLRequest created for the request
 * This can be used to modify properties of the POST, for example timeout or cache protocol
 * @param block A function to be called when the post finishes. The block should handle both SUCCESS and FAILURE
 */
+ (void)postAsync:(NSString *)url requestPreparer:(SRPrepareRequestBlock)requestPreparer completionHandler:(SRCompletionHandler)block;

/**
 * Creates a POST request with the specified url and payload returns on the given block
 * This POST will have a payload that is generated from @postData
 *
 * @param url The url relative to the server endpoint
 * @param postData An Object that conforms to SRSerializable to post at the url
 * @param block A function to be called when the post finishes. The block should handle both SUCCESS and FAILURE
 */
+ (void)postAsync:(NSString *)url postData:(id)postData completionHandler:(SRCompletionHandler)block;

/**
 * Creates a POST request with the specified url and payload returns on the given block
 * This POST will have a payload that is generated from @postData
 *
 * @param url The url relative to the server endpoint
 * @param postData An Object that conforms to SRSerializable to post at the url
 * @param requestPreparer A function to be called on the NSMutableURLRequest created for the request
 * This can be used to modify properties of the POST, for example timeout or cache protocol
 * @param block A function to be called when the post finishes. The block should handle both SUCCESS and FAILURE
 */
+ (void)postAsync:(NSString *)url requestPreparer:(SRPrepareRequestBlock)requestPreparer postData:(id)postData completionHandler:(SRCompletionHandler)block;

@end
