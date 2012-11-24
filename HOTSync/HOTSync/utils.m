//
//  utils.m
//  HOTSync
//
//  Created by Jose Avila III on 10/27/12.
//  Copyright (c) 2012 Jose Avila III. All rights reserved.
//

#import "utils.h"

#pragma mark NSJSONSerialization

@implementation NSJSONSerialization (stringWithJsonObject)

+ (NSString *)stringWithJSONObject:(id)obj options:(NSJSONWritingOptions)opt error:(NSError **)error{
    NSString *string = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:obj options:opt error:error] encoding:NSUTF8StringEncoding];
    return string;
}

+ (id)objectWithJSONString:(NSString *)string{
    return [NSJSONSerialization JSONObjectWithData:[string dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
}
@end

#pragma mark NSDictionary

@implementation NSDictionary (MutableCopyDeep)

-(NSMutableDictionary *)mutableCopyDeep{
    NSMutableDictionary * ret = [[NSMutableDictionary alloc] initWithCapacity: [self count]];
    NSArray *keys = [self allKeys];
    for (id key in keys){
        id oneValue = [self valueForKey:key];
        id oneCopy = nil;
        if([oneValue isKindOfClass:[NSNull class]]){
            oneCopy = oneValue;
        } else if ([oneValue respondsToSelector: @selector(mutableCopyDeep)]){
            oneCopy = [oneValue mutableCopyDeep];
            // For seome reason NSNumber has mutableCopy :/
        } else if ([oneValue respondsToSelector:@selector(mutableCopy)] && ![oneValue isKindOfClass:[NSNumber class]]){
            oneCopy = [oneValue mutableCopy];
        } else if([oneValue respondsToSelector:@selector(copy)]){
            oneCopy = [oneValue copy];
        } else {
            oneCopy = oneValue;
        }
        [ret setValue:oneCopy forKey:key];
    }
    return ret;
    
}

@end

#pragma mark UIDevice

@implementation UIDevice (Identifier)

-(NSString *)identifier{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *deviceId = [prefs valueForKey:@"UIDevice.identifier"];
    if(!deviceId || [deviceId isEqualToString:@""]){
        CFUUIDRef theUUID = CFUUIDCreate(kCFAllocatorDefault);
        if (theUUID)
        {
            deviceId = (__bridge NSString *)CFUUIDCreateString(kCFAllocatorDefault, theUUID);
            [prefs setValue:deviceId forKey:@"UIDevice.identifier"];
            CFRelease(theUUID);
        }
    }
    return deviceId;
}

@end