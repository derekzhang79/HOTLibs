//
//  HOTInflector.h
//  HOTModel
//
//  Created by Jose Avila III on 11/21/12.
//  Copyright (c) 2012 Jose Avila III. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HOTInflector : NSObject

+(NSString *)underscoreCamelCaseWord:(NSString *)word;
+(NSString *)pluralizeWord:(NSString *)word;
+(NSString *)tableize:(NSString *)className;

@end
