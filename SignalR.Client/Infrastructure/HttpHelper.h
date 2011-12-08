//
//  HttpHelper.h
//  SignalR
//
//  Created by Alex Billingsley on 10/18/11.
//  Copyright (c) 2011 DyKnow LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRConnection.h"
#import "HttpRequest.h"
#import "NSString+Url.h"

@class SRConnection;

@interface HttpHelper : NSObject
{
    NSMutableDictionary *requests;

}
@property (nonatomic, strong, readonly) NSMutableDictionary *requests;

+ (HttpHelper *)sharedHttpRequestManager;

- (void)postAsync:(SRConnection *)connection url:(NSString *)url onCompletion:(void(^)(SRConnection *, id))block;
- (void)postAsync:(SRConnection *)connection url:(NSString *)url requestPreparer:(void(^)(NSMutableURLRequest *))requestPreparer onCompletion:(void(^)(SRConnection *, id))block;
- (void)postAsync:(SRConnection *)connection url:(NSString *)url requestPreparer:(void(^)(NSMutableURLRequest *))requestPreparer postData:(NSDictionary *)postData onCompletion:(void(^)(SRConnection *, id))block;

@end
