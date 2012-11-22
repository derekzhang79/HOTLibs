//
//  Change.m
//  HOTSync
//
//  Created by Jose Avila III on 10/27/12.
//  Copyright (c) 2012 Jose Avila III. All rights reserved.
//
//  TODO: (High) Create table if it doesnt already exist

#import "Change.h"

@implementation Change

-(id)initWithModelManager:(HOTModelManager *)modelMgr andSyncClinet:(HOTSync *)syncClient{
    self = [super initWithModelManager:modelMgr];
    if(self){
        // Initialization code here.
        _useDbConfig = @"local";
        _createTableIfNotPresent = YES;
        _createTableSchema = [NSString stringWithFormat:@"CREATE TABLE '%@' ( 'id' INTEGER PRIMARY KEY AUTOINCREMENT, 'remote_call_id' INTEGER NOT NULL , 'action' TEXT , 'model_name' TEXT not null, 'primary_key1' TEXT, 'primary_key2' TEXT, 'data' TEXT )", _table];
        [self createTableSchema];
    }
    return self;
}

@end
