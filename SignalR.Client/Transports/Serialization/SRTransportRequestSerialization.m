//
//  SRTransportRequestSerialization.m
//  SignalR.Client.ObjC
//
//  Created by Alex Billingsley on 7/26/16.
//  Copyright © 2016 DyKnow LLC. All rights reserved.
//

#import "SRTransportRequestSerialization.h"

@implementation SRTransportRequestSerializer

+ (instancetype)serializer {
    return [self serializerWithConnection:nil];
}

+ (instancetype)serializerWithConnection:(id <SRConnectionInterface>)connection {
    SRTransportRequestSerializer *serializer = [[self alloc] init];
    serializer.connection = connection;
    return serializer;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    NSString *clientVersion = @"2.0.0.0";
    NSString *userAgent = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
#if TARGET_OS_IOS
    // User-Agent Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.43
    userAgent = [NSString stringWithFormat:@"SignalR.Client/%@ (%@; iOS %@; Scale/%0.2f)", clientVersion, [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], [[UIScreen mainScreen] scale]];
#elif TARGET_OS_WATCH
    // User-Agent Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.43
    userAgent = [NSString stringWithFormat:@"SignalR.Client/%@ (%@; watchOS %@; Scale/%0.2f)", clientVersion, [[WKInterfaceDevice currentDevice] model], [[WKInterfaceDevice currentDevice] systemVersion], [[WKInterfaceDevice currentDevice] screenScale]];
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
    userAgent = [NSString stringWithFormat:@"SignalR.Client/%@ (Mac OS X %@)", clientVersion, [[NSProcessInfo processInfo] operatingSystemVersionString]];
#endif
#pragma clang diagnostic pop
    if (userAgent) {
        if (![userAgent canBeConvertedToEncoding:NSASCIIStringEncoding]) {
            NSMutableString *mutableUserAgent = [userAgent mutableCopy];
            if (CFStringTransform((__bridge CFMutableStringRef)(mutableUserAgent), NULL, (__bridge CFStringRef)@"Any-Latin; Latin-ASCII; [:^ASCII:] Remove", false)) {
                userAgent = mutableUserAgent;
            }
        }
        [self setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    }
    
    return self;
}

- (NSDictionary *)addMessageId:(NSDictionary *)parameters {
    if ([self.connection messageId]) {
        NSMutableDictionary *_parameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
        [_parameters addEntriesFromDictionary:@{
            @"messageId" : [self.connection messageId]
        }];
        return _parameters;
    }
    return parameters;
}

- (NSDictionary *)addGroupsToken:(NSDictionary *)parameters {
    if ([self.connection groupsToken]) {
        NSMutableDictionary *_parameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
        [_parameters addEntriesFromDictionary:@{
            @"groupsToken" : [self.connection groupsToken]
        }];
        return _parameters;
    }
    return parameters;
}

- (NSDictionary *)addConnectionData:(NSDictionary *)parameters connectionData:(NSString *)connectionData {
    if (connectionData) {
        NSMutableDictionary *_parameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
        [_parameters addEntriesFromDictionary:@{
            @"connectionData" : connectionData
        }];
        return _parameters;
    }
    return parameters;
}

- (NSDictionary *)addConnectionToken:(NSDictionary *)parameters {
    if ([self.connection connectionToken]) {
        NSMutableDictionary *_parameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
        [_parameters addEntriesFromDictionary:@{
            @"connectionToken" : [self.connection connectionToken]
        }];
        return _parameters;
    }
    return parameters;
}

- (NSDictionary *)addQueryString:(NSDictionary *)parameters {
    if ([self.connection queryString]) {
        NSMutableDictionary *_parameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
        [_parameters addEntriesFromDictionary:[self.connection queryString]];
        return _parameters;
    }
    return parameters;
}

#pragma mark - AFURLRequestSerialization

- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request
                               withParameters:(id)parameters
                                        error:(NSError *__autoreleasing *)error {
    NSParameterAssert(request);
    
    //parameters = [self addTransport:parameters transport:[self name]];
    //parameters = [self addConnectionData:parameters connectionData:connectionData];
    parameters = [self addConnectionToken:parameters ?: @{}];
    parameters = [self addMessageId:parameters];
    parameters = [self addGroupsToken:parameters];
    parameters = [self addQueryString:parameters];
    
    return [super requestBySerializingRequest:request withParameters:parameters error:error];
}

@end

@implementation SRLongPollingRequestSerializer

#pragma mark - AFURLRequestSerialization

- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request
                               withParameters:(id)parameters
                                        error:(NSError *__autoreleasing *)error {
    NSParameterAssert(request);
    
    NSMutableURLRequest *mutableRequest = [[super requestBySerializingRequest:request withParameters:parameters error:error] mutableCopy];
    [mutableRequest setTimeoutInterval:240];
    return mutableRequest;
}

@end

@implementation SREventSourceRequestSerializer

#pragma mark - AFURLRequestSerialization

- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request
                               withParameters:(id)parameters
                                        error:(NSError *__autoreleasing *)error {
    NSParameterAssert(request);
    
    NSMutableURLRequest *mutableRequest = [[super requestBySerializingRequest:request withParameters:parameters error:error] mutableCopy];
    [mutableRequest setValue:@"text/event-stream" forHTTPHeaderField:@"Accept"];
    [mutableRequest setValue:@"Keep-Alive" forHTTPHeaderField:@"Connection"];
    [mutableRequest setTimeoutInterval:240];
    return mutableRequest;
}

@end

@implementation SRWebsocketRequestSerializer

@end