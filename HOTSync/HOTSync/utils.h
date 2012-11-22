//
//  utils.h
//  HOTSync
//
//  Created by Jose Avila III on 10/27/12.
//  Copyright (c) 2012 Jose Avila III. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark NSJSONSerialization

@interface NSJSONSerialization (stringWithJsonObject)

+ (NSString *)stringWithJSONObject:(id)obj options:(NSJSONWritingOptions)opt error:(NSError **)error;
+ (id)objectWithJSONString:(NSString *)string;
@end

#pragma mark NSDictionary

@interface NSDictionary (NSDictionaryMutableCopyDeep)

- (NSMutableDictionary *) mutableCopyDeep;

@end
