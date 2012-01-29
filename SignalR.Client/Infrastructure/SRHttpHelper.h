//
//  SRHttpHelper.h
//  SignalR
//
//  Created by Alex Billingsley on 10/18/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SRHttpHelper : NSObject

+ (id)sharedHttpRequestManager;

#pragma mark -
#pragma mark GET Requests
/**
 * Creates a GET request with the specified url returns on the given block
 * 
 * @param url: The url relative to the server endpoint
 * @param block: A function to be called when the post finishes. The block should handle both SUCCESS and FAILURE
 */
+ (void)getAsync:(NSString *)url continueWith:(void (^)(id response))block;

/**
 * Creates a GET request with the specified url returns on the given block
 *
 * @param url: The url relative to the server endpoint
 * @param requestPreparer: A function to be called on the NSMutableURLRequest created for the request
 * This can be used to modify properties of the POST, for example timeout or cache protocol
 * @param block: A function to be called when the post finishes. The block should handle both SUCCESS and FAILURE
 */
+ (void)getAsync:(NSString *)url requestPreparer:(void(^)(id))requestPreparer continueWith:(void (^)(id response))block;

/**
 * Creates a GET request with the specified url returns on the given block
 *
 * @param url: The url relative to the server endpoint
 * @param parameters: An Object that conforms to proxyForJSON to pass as parameters to the endpoint
 * This can be used to modify properties of the POST, for example timeout or cache protocol
 * @param block: A function to be called when the post finishes. The block should handle both SUCCESS and FAILURE
 */
+ (void)getAsync:(NSString *)url parameters:(id)parameters continueWith:(void (^)(id response))block;

/**
 * Creates a GET request with the specified url returns on the given block
 *
 * @param url: The url relative to the server endpoint
 * @param parameters: An Object that conforms to proxyForJSON to pass as parameters to the endpoint
 * @param requestPreparer: A function to be called on the NSMutableURLRequest created for the request
 * This can be used to modify properties of the POST, for example timeout or cache protocol
 * @param block: A function to be called when the post finishes. The block should handle both SUCCESS and FAILURE
 */
+ (void)getAsync:(NSString *)url requestPreparer:(void(^)(id))requestPreparer parameters:(id)parameters continueWith:(void (^)(id response))block;

#pragma mark -
#pragma mark POST Requests
/**
 * Creates a POST request with the specified url returns on the given block
 * This POST will contain no payload
 * 
 * @param url: The url relative to the server endpoint
 * @param block: A function to be called when the post finishes. The block should handle both SUCCESS and FAILURE
 */
+ (void)postAsync:(NSString *)url continueWith:(void (^)(id response))block;

/**
 * Creates a POST request with the specified url returns on the given block
 * This POST will contain no payload
 *
 * @param url: The url relative to the server endpoint
 * @param requestPreparer: A function to be called on the NSMutableURLRequest created for the request
 * This can be used to modify properties of the POST, for example timeout or cache protocol
 * @param block: A function to be called when the post finishes. The block should handle both SUCCESS and FAILURE
 */
+ (void)postAsync:(NSString *)url requestPreparer:(void(^)(id))requestPreparer continueWith:(void (^)(id response))block;

/**
 * Creates a POST request with the specified url and payload returns on the given block
 * This POST will have a payload that is generated from @postData
 *
 * @param url: The url relative to the server endpoint
 * @param postData: An Object that conforms to proxyForJSON to post at the url
 * @param block: A function to be called when the post finishes. The block should handle both SUCCESS and FAILURE
 */
+ (void)postAsync:(NSString *)url postData:(id)postData continueWith:(void (^)(id response))block;

/**
 * Creates a POST request with the specified url and payload returns on the given block
 * This POST will have a payload that is generated from @postData
 *
 * @param url: The url relative to the server endpoint
 * @param postData: An Object that conforms to proxyForJSON to post at the url
 * @param requestPreparer: A function to be called on the NSMutableURLRequest created for the request
 * This can be used to modify properties of the POST, for example timeout or cache protocol
 * @param block: A function to be called when the post finishes. The block should handle both SUCCESS and FAILURE
 */
+ (void)postAsync:(NSString *)url requestPreparer:(void(^)(id))requestPreparer postData:(id)postData continueWith:(void (^)(id response))block;

@end
