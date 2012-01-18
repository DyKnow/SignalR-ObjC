//
//  SRSBJSON.h
//  SignalR
//
//  Created by Alex Billingsley on 1/7/12.
//  Copyright (c) 2012 DyKnow LLC. All rights reserved.
//

/**
 * All Models should implement this protocol even if to only return an empty method
 * This will ensure that all models can be JSON Stringifed and converted from a JSON Object
 * to the model object
 */
@protocol SRSBJSON <NSObject>

/**
 * init should set the defaults for each instance field
 * @code
 * - (id) init {
 *  if(self = [super init]) {
 *      _anNSInteger = 0;
 *      _anNSString = [NSString stringWithFormat:@""];
 *  }
 *  return self;
 * @endcode
 */
- (id) init;

/**
 * initWithDictionary should call init to set defaults, 
 * then apply the corresponding values from the dictionary
 * @code
 * - (id) initWithDictionary:(NSDictionary *)dict
 *  if(self = [self init]) {
 *      _anNSInteger = [[dict objectForKey:kIntegerKey] integerValue];
 *      _anNSString = [dict objectForKey:kStringKey];
 *  }
 *  return self;
 * @endcode
 */
- (id) initWithDictionary:(NSDictionary *)dict;

/**
 * updateWithDictionary apply the corresponding values from the dictionary
 * @code
 * - (id) updateWithDictionary:(NSDictionary *)dict
 *  if(self = [self init]) {
 *      _anNSInteger = [[dict objectForKey:kIntegerKey] integerValue];
 *      _anNSString = [dict objectForKey:kStringKey];
 *  }
 *  return self;
 * @endcode
 */
- (void) updateWithDictionary:(NSDictionary *)dict;

/**
 * proxyForJson converts the model object to an object that can be stringified by SBJSON
 * this is typically an NSDictionary but could also be an NSArray
 * @code
 * - (id) proxyForJson {
 *  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
 *  
 *  [dict setObject:[NSNumber numberWithInt:_anNSInteger] forKey:kIntegerKey];
 *  [dict setObject:[NSString stringWithFormat:@"%@",_anNSString] forKey:kNSStringKey];
 * 
 *  return dict;
 * @endcode
 */
- (id) proxyForJson;

@end
