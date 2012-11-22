//
//  RemoteCall.m
//  HOTSync
//
//  Created by Jose Avila III on 10/27/12.
//  Copyright (c) 2012 Jose Avila III. All rights reserved.
//
//  TODO: (High) Create table if it doesnt already exist

#import "RemoteCall.h"

@implementation RemoteCall

-(id)initWithModelManager:(HOTModelManager *)modelMgr andSyncClinet:(HOTSync *)syncClient{
    self = [super initWithModelManager:modelMgr];
    if(self){
        // Initialization code here.
        _useDbConfig = @"local";
        _createTableIfNotPresent = YES;
        _createTableSchema = [NSString stringWithFormat:@"CREATE TABLE '%@' ('id' INTEGER PRIMARY KEY AUTOINCREMENT, 'method' TEXT, 'post_data' TEXT, 'status' TEXT DEFAULT 'PENDING' ) ;", _table];
        [self createTableSchema];
    }
    return self;
}


@end
