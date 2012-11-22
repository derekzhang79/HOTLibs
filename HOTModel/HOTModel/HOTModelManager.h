//
//  HOTModelManager.h
//  HOTModel
//
//  Created by Jose Avila III on 11/21/12.
//  Copyright (c) 2012 Jose Avila III. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HOTDatabase.h"
#import "HOTModel.h"

@interface HOTModelManager : NSObject {
    NSDictionary *_models;
    NSMutableArray *_sqlLog;
    int _maxSqlLogs; // Defines the maximum number of sql logs the logger should hold
    NSMutableDictionary *_datasources; // The Datasources
}


-(id)initWithConfig:(NSDictionary *)config;
-(HOTDatabase *)getDatabaseWithDatasource:(NSString *)datasource;
-(void)addDatasourceWithName:(NSString *)dataSourceName andConfig:(NSDictionary *)config;

-(void)registerModel:(HOTModel *)model;
-(HOTModel *)modelWithName:(NSString *)name;
-(void)logQueryWithQuery:(NSString *)sql andError:(NSNumber *)error andAffected:(NSNumber *)affected andNumRows:(NSNumber *)numRows andTookTime:(NSNumber *)time;

@end
