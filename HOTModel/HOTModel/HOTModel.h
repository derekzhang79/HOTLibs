//
//  HOTModel.h
//  HOTModel
//
//  Created by Jose Avila III on 11/21/12.
//  Copyright (c) 2012 Jose Avila III. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

#import "HOTInflector.h"

@class HOTModelManager;

@interface HOTModel : NSObject {
    HOTModelManager *_modelManager;
    NSString *_useDbConfig;
    NSString *_useTable;
    NSString *_displayField;
    NSArray *_primaryKeys;
    NSString *_name; // Name of the model
    NSString *_alias; // Alias name of the model
    NSString *_order; //
    NSString *_findQueryType; // Type of find query currently executing.
    NSString *_table;
    BOOL _inserting;
    sqlite3 *_database;
    NSNumber *_insertedId;
    NSDictionary *_schema;
    BOOL _createTableIfNotPresent; // If set to yes the model will create the table if it is not present
    NSString *_createTableSchema; // The definition of the table schema
}

@property (strong) HOTModelManager *modelManager;
@property (strong) NSString *useDbConfig;
@property (strong) NSString *useTable;
@property (strong) NSString *displayField;
@property (strong) NSArray *primaryKeys;
@property (strong) NSString *name;
@property (strong) NSString *alias;
@property (strong) NSString *order;
@property (strong) NSString *findQueryType;
@property (strong) NSString *table;
@property (assign) BOOL inserting;
@property (assign) sqlite3 *database;
@property (strong) NSNumber *insertedId;


-(id)initWithModelManager:(HOTModelManager *)modelMgr;
-(void)createTableSchema;

-(NSArray *)dataSourceExecuteWithSql:(NSString *)sql;
-(id)findWithType:(NSString *)type andQuery:(NSDictionary *)query;
-(NSDictionary *)schema;
-(NSString *)buildStatementJoinsWithQueryData:(NSArray *)data;

-(NSString *)buildStatementWithQueryData:(NSDictionary *)queryData;
-(NSString *)buildInsertStatementWithData:(NSDictionary *)data;
-(NSString *)buildUpdateStatementWithData:(NSDictionary *)data;
-(NSString *)buildDeleteStatementWithData:(NSDictionary *)queryData;
-(NSDictionary *)buildQueryWithQuery:(NSDictionary *)query;
-(BOOL)hasField:(NSString *)field;

-(void)create;
-(BOOL)saveWithData:(NSDictionary *)data andValidate:(BOOL)validate andFieldList:(NSArray *)fieldList;
-(BOOL)saveWithData:(NSDictionary *)data;
-(BOOL)deleteWithQueryData:(NSDictionary *)queryData;


@end
