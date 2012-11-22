//
//  HOTModelManager.m
//  HOTModel
//
//  Created by Jose Avila III on 11/21/12.
//  Copyright (c) 2012 Jose Avila III. All rights reserved.
//

#import "HOTModelManager.h"

@implementation HOTModelManager

/**
 *  {<DataSourceName>:{'Path':<FileSystemPath>}}
 */
-(id)initWithConfig:(NSDictionary *)config{
    self = [super init];
    if(self){
        _datasources = [[NSMutableDictionary alloc] init];
        for (NSString *dataSourceName in [config allKeys]){
            [self addDatasourceWithName:dataSourceName andConfig:[config objectForKey:dataSourceName]];
        }
        //_config = config;
        _maxSqlLogs = 100;
    }
    return self;
}

-(void)addDatasourceWithName:(NSString *)dataSourceName andConfig:(NSDictionary* )config{
    if([config objectForKey:@"Path"]!=nil){
        HOTDatabase *db = [[HOTDatabase alloc] initWithPath:[config objectForKey:@"Path"]];
        [_datasources setObject:db forKey:dataSourceName];
    }
    
}
/**
 * Returns the database requested
 */
-(HOTDatabase *)getDatabaseWithDatasource:(NSString *)datasource{
    return [_datasources objectForKey:datasource];
}

-(void)registerModel:(HOTModel *)model{
    [_models setValue:model forKey:[model name]];
}

-(HOTModel *)modelWithName:(NSString *)name{
    return [_models objectForKey:name];
}

-(void)logQueryWithQuery:(NSString *)sql andError:(NSNumber *)error andAffected:(NSNumber *)affected andNumRows:(NSNumber *)numRows andTookTime:(NSNumber *)time{
    // If we have too many logs, clear out the oldest log
    if([_sqlLog count] >= _maxSqlLogs){
        [_sqlLog removeObjectAtIndex:0];
    }
    // store the log into the object
    NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                          sql, @"sql",
                          error, @"error",
                          affected, @"affected",
                          numRows, @"numRows",
                          time, @"time",
                          nil];
    [_sqlLog addObject:data];
}


@end
