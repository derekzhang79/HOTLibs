//
//  HOTModel.m
//  HOTModel
//
//  Created by Jose Avila III on 11/21/12.
//  Copyright (c) 2012 Jose Avila III. All rights reserved.
//

#import "HOTModel.h"
#import "HOTModelManager.h"

@implementation HOTModel

-(id)init{
    self = [super init];
    if (self) {
        // Initialization code here.
        // Get the model name from the class name
        [self setName:NSStringFromClass([self class])];
        // Get the alias name from the class name
        [self setAlias:NSStringFromClass([self class])];
        // Set the primary keys
        [self setPrimaryKeys:[[NSArray alloc] initWithObjects:@"id", nil]];
        // Set the datasource
        [self setUseDbConfig:@"default"];
        // Set the table
        [self setTable:[HOTInflector tableize:NSStringFromClass([self class])]];
    }
    return self;
    
}

-(id)initWithModelManager:(HOTModelManager *)modelMgr{
    self = [super init];
    if(self){
        // Initialization code here.
        // Get the model name from the class name
        [self setName:NSStringFromClass([self class])];
        // Get the alias name from the class name
        [self setAlias:NSStringFromClass([self class])];
        // Set the primary keys
        [self setPrimaryKeys:[[NSArray alloc] initWithObjects:@"id", nil]];
        // Set the datasource
        [self setUseDbConfig:@"default"];
        // Set the table
        [self setTable:[HOTInflector tableize:NSStringFromClass([self class])]];
        // Set the model Manager
        [self setModelManager:modelMgr];
        //[self setDatabase:[modelMgr database]];
        _createTableIfNotPresent = NO;
    }
    return self;
}

-(void)createTableSchema{
    if(_createTableIfNotPresent && _createTableSchema){
        // check the schema to see if it exists.
        _schema = nil;
        NSDictionary *schema = [self schema];
        if([[schema allKeys] count] == 0){
            [self dataSourceExecuteWithSql:_createTableSchema];
            _schema = nil;
        }
    }
}

# pragma mark Datasource Methods
-(sqlite3 *)openDatabase{
    return [[_modelManager getDatabaseWithDatasource:_useDbConfig] openDatabase];
}
-(void)closeDatabase:(sqlite3 *)db{
    [[_modelManager getDatabaseWithDatasource:_useDbConfig] closeDatabase:db];
}
/**
 *
 */
-(NSArray *)dataSourceExecuteWithSql:(NSString *)sql{
    sqlite3 *db = [self openDatabase];
    // Prepare the SQL
    sqlite3_stmt *statement;
    NSDate *start = [NSDate date];
    if(sqlite3_prepare_v2(db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK){
        // Iterate over the returned rows
        // Find out what columns exist in the result set
        NSMutableArray *columns = [[NSMutableArray alloc] init];
        for(int idx=0; idx< sqlite3_column_count(statement); idx++){
            // add the column name to the array of columns
            [columns addObject:[[NSString alloc] initWithUTF8String:(char *)sqlite3_column_name(statement, idx)]];
        }
        // iterate over the results
        
        NSMutableArray *results = [[NSMutableArray alloc] init];
        while (sqlite3_step(statement) == SQLITE_ROW){
            NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
            id data = nil;
            int idx = 0;
            for (NSString *column in columns) {
                int ctype = sqlite3_column_type(statement, idx);
                if(ctype == SQLITE_INTEGER){
                    data = [NSNumber numberWithInt:sqlite3_column_int(statement, idx)];
                } else if (ctype == SQLITE_FLOAT){
                    data = [NSNumber numberWithFloat:(float)sqlite3_column_double(statement, idx)];
                } else if (ctype == SQLITE_TEXT){
                    char *c = (char *)sqlite3_column_text(statement, idx);
                    if(c != nil){
                        data = [[NSString alloc]initWithUTF8String:c];
                    }
                } else if(ctype == SQLITE_NULL){
                    data = [[NSNull alloc] init];
                } else {
                    NSLog(@"Unsupported Data Type %d", ctype);
                    
                }
                if(data != nil){
                    [result setValue:data forKey:[columns objectAtIndex:idx]];
                }
                idx++;
            }
            // append the result object to the results
            [results addObject:result];
        }
        if(_inserting){
            _insertedId =  [NSNumber numberWithInt:sqlite3_last_insert_rowid(db)];
        }
        // Log the query
        NSTimeInterval timeInterval = -[start timeIntervalSinceNow]*1000;
        [_modelManager logQueryWithQuery:sql
                                andError:[NSNumber numberWithInt:0]
                             andAffected:[NSNumber numberWithInt:sqlite3_changes(db)]
                              andNumRows:[NSNumber numberWithInt:[results count]]
                             andTookTime:[NSNumber numberWithInt:(int)timeInterval]];
        [self closeDatabase:db];
        return results;
    } else {
        NSLog(@"ONZRAModel: There was an error preparing SQL Statement! %@", [NSString stringWithUTF8String:sqlite3_errmsg(db)]);
    }
    [self closeDatabase:db];
    return nil;
}
/**
 * Returns an array of the fields in given table name.
 */
-(NSDictionary *)dataSourceDescribe{
    NSString *sql = [NSString stringWithFormat:@"PRAGMA table_info(%@)", [self table]];
    NSArray *results =  [self dataSourceExecuteWithSql:sql];
    NSMutableDictionary *fields = [[NSMutableDictionary alloc] init];
    for(NSDictionary *column in results){
        NSMutableDictionary *columnData = [[NSMutableDictionary alloc] init];
        [columnData setValue:[column valueForKey:@"name"] forKey:@"name"];
        [columnData setValue:[column valueForKey:@"type"] forKey:@"type"];
        if([[column valueForKey:@"notnull"] intValue] == 1){
            [columnData setValue:[NSNumber numberWithInt:0] forKey:@"nullable"];
        } else {
            [columnData setValue:[NSNumber numberWithInt:1] forKey:@"nullable"];
        }
        [fields setValue:columnData forKey:[columnData valueForKey:@"name"]];
    }
    return fields;
}

-(NSString *)buildStatementFields:(NSArray *)fields{
    return [NSString stringWithFormat:@"%@", [fields componentsJoinedByString:@","]];
}
-(NSString *)buildStatementTable{
    return [NSString stringWithFormat:@"%@ as %@", _table, _name];
}
-(NSString *)buildStatementWhere:(NSDictionary *)conditions andJoinBy:(NSString *)joinBy{
    return [self buildStatementWhere:conditions andJoinBy:joinBy withModelInColumnName:YES];
}
-(NSString *)buildStatementWhere:(NSDictionary *)conditions andJoinBy:(NSString *)joinBy withModelInColumnName:(BOOL)includeModel{
    NSString *conditions_str = @"";
    if(conditions != nil){
        NSMutableArray *condition_array = [[NSMutableArray alloc] init];
        // WHY THE FUCK ISNT COL A STRING when Iterating oer mutliple times.
        for(NSString *c in [conditions allKeys]){
            NSString *col = [c stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            id value = [conditions objectForKey:col];
            if([value isKindOfClass:[NSString class]]){
                value = [value stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
            }
            
            if(![value isKindOfClass:[NSNumber class]]){
                value = [NSString stringWithFormat:@"'%@'", value];
            }
            if(!includeModel){
                NSMutableArray *components = [[col componentsSeparatedByString:@"."] mutableCopy];
                [components removeObjectAtIndex:0];
                col = [components componentsJoinedByString:@"."];
            }
            if([[col lowercaseString] isEqualToString:@"or"]){
                // This is an or clause we need to iterate down
                NSString *childGroup = [self buildStatementWhere:[conditions objectForKey:col] andJoinBy:@"OR" withModelInColumnName:includeModel];
                [condition_array addObject:[NSString stringWithFormat:@"(%@)", childGroup]];
            } else if([[col componentsSeparatedByString:@" "] count] > 1) {
                // there is whitespace in the string
                if([[col lowercaseString] hasSuffix:@"is null"]){
                    // This is a null field
                    [condition_array addObject:col];
                } else {
                    // This is a like, !=, >, etc.
                    [condition_array addObject:[NSString stringWithFormat:@"%@ %@", col, value]];
                }
            } else {
                // This should be a normal =
                [condition_array addObject:[NSString stringWithFormat:@"%@=%@", col, value]];
            }
        }
        conditions_str = [condition_array componentsJoinedByString:[NSString stringWithFormat:@" %@ ", joinBy]];
    } else {
        conditions_str = @"1";
    }
    return conditions_str;
}

-(NSString *)buildStatementLimitWithLimit:(NSNumber *)limit andOffset:(NSNumber *)offset{
    NSMutableString *sql = [[NSMutableString alloc] initWithString:@""];
    if(limit != nil){
        [sql appendFormat:@"LIMIT %d", [(NSNumber *)limit intValue]];
        if(offset != nil){
            [sql appendFormat:@" OFFSET %d", [(NSNumber *)offset intValue]];
        }
    }
    return sql;
}
-(NSString *)buildStatementJoinsWithQueryData:(NSArray *)data{
    /*
     *   array(
     *       'table' => 'channels',
     *       'alias' => 'Channel',
     *       'type' => 'LEFT',
     *       'conditions' => array(
     *           'Channel.id = Item.channel_id',
     *       )
     *   );
     */
    NSMutableString *sql = [[NSMutableString alloc] initWithString:@""];
    if(data != nil){
        for(NSDictionary *joinData in data){
            //
            NSString *conditionsStr = [[joinData objectForKey:@"conditions"] componentsJoinedByString:@" AND "];
            [sql appendFormat:@" %@ JOIN %@ AS %@ ON %@", [joinData objectForKey:@"type"], [joinData objectForKey:@"table"], [joinData objectForKey:@"alias"], conditionsStr];
        }
    }
    return sql;
}
-(NSString *)buildStatementWithQueryData:(NSDictionary *)queryData{
    
    // build the query array - $query = $this->buildQuery($type, $query);
    NSString *fieldSql = [self buildStatementFields:[queryData objectForKey:@"fields"]];
    NSString *tableSql = [self buildStatementTable];
    NSString *whereSql = [self buildStatementWhere:[queryData objectForKey:@"conditions"] andJoinBy:@"and"];
    NSString *joinSql = [self buildStatementJoinsWithQueryData:[queryData objectForKey:@"joins"]];
    NSString *limitOffsetSql = [self buildStatementLimitWithLimit:[queryData objectForKey:@"limit"] andOffset:[queryData objectForKey:@"offset"]];
    NSString *sql = [NSString stringWithFormat:@"SELECT %@ FROM %@%@ WHERE %@ %@", fieldSql, tableSql, joinSql, whereSql, limitOffsetSql];
    return [sql stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

/**
 * Build the SQL for a insert
 */
-(NSString *)buildInsertStatementWithData:(NSDictionary *)data{
    NSMutableArray *columns = [[NSMutableArray alloc] init];
    NSMutableArray *values = [[NSMutableArray alloc] init];
    for(NSString *colName in [data objectForKey:_name]){
        id value = [data valueForKeyPath:[NSString stringWithFormat:@"%@.%@", _name, colName]];
        if([value isKindOfClass:[NSNull class]]){
            value = @"NULL";
        } else {
            if([value isKindOfClass:[NSString class]]){
                value = [value stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
            }
            if(![value isKindOfClass:[NSNumber class]]){
                value = [NSString stringWithFormat:@"'%@'", value];
            }
        }
        [columns addObject:colName];
        [values addObject:value];
    }
    NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)", _table, [columns componentsJoinedByString:@","], [values componentsJoinedByString:@","]];
    return sql;
}

/**
 * Build the SQL for a update
 */
-(NSString *)buildUpdateStatementWithData:(NSDictionary *)data{
    NSMutableArray *updates = [[NSMutableArray alloc] init];
    NSMutableArray *conditional = [[NSMutableArray alloc] init];
    for(NSString *colName in [data objectForKey:_name]){
        BOOL isPrimaryKey = NO;
        // Set the adjust the value for future use
        id value = [data valueForKeyPath:[NSString stringWithFormat:@"%@.%@", _name, colName]];
        if([value isKindOfClass:[NSNull class]]){
            value = @"NULL";
        } else {
            if([value isKindOfClass:[NSString class]]){
                value = [value stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
            }
            if(![value isKindOfClass:[NSNumber class]]){
                value = [NSString stringWithFormat:@"'%@'", value];
            }
        }
        // detect if this is going to be a primaryKey
        for (NSString *primaryKey in _primaryKeys){
            if ([colName isEqualToString:primaryKey]){
                // This is a primary key. Add it to the conditional.
                [conditional addObject:[NSString stringWithFormat:@"%@=%@", colName, value]];
                isPrimaryKey = YES;
                break;
            }
        }
        if(isPrimaryKey){
            continue;
        }
        // Add this to a list of updates.
        [updates addObject:[NSString stringWithFormat:@"%@=%@", colName, value]];
    }
    NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@", _table, [updates componentsJoinedByString:@","], [conditional componentsJoinedByString:@","]];
    return sql;
}

-(NSString *)buildDeleteStatementWithData:(NSDictionary *)queryData{
    NSString *conditions_str = [self buildStatementWhere:[queryData objectForKey:@"conditions"] andJoinBy:@"AND" withModelInColumnName:NO];
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@", _table, conditions_str];
    return sql;
}
/**
 * Reads record(s) from the database.
 */
-(NSArray *)dataSourceReadWithQueryData:(NSDictionary *)queryData{
    NSString *sql = [self buildStatementWithQueryData:queryData];
    NSArray *results = [self dataSourceExecuteWithSql:sql];
    return results;
}

/**
 * Generates the fields list of an SQL query.
 */
-(NSArray *)dataSourceFields:(NSArray *)fields{
    NSMutableArray *quotedFields = [[NSMutableArray alloc] init];
    if([fields count] == 0){
        for(NSString *field in [[self schema] allKeys]){
            [quotedFields addObject:[NSString stringWithFormat:@"%@.%@", _name, field]];
        }
    }else {
        for(NSString *field in fields){
            NSArray *modelColumnArray = [field componentsSeparatedByString:@"."];
            NSString *modelName = [modelColumnArray objectAtIndex:0];
            NSString *columnName = [modelColumnArray objectAtIndex:1];
            if([columnName isEqualToString:@"*"]){
                // we need to add all fields for this model
                if([modelName isEqualToString:_name]){
                    // Add the fields from that schema
                    for(NSString *field in [[self schema] allKeys]){
                        [quotedFields addObject:[NSString stringWithFormat:@"%@.%@", _name, field]];
                    }
                } else {
                    // TODO: (Low) Load fields from schema from other model
                }
            } else {
                [quotedFields addObject:field];
            }
            
        }
    }
    return quotedFields;
}

# pragma mark Model Methods

/**
 * Returns an array of table metadata (column names and types) from the database.
 */
-(NSDictionary *)schema{
    if(_schema == nil){
        _schema = [self dataSourceDescribe];
    }
    return _schema;
}

-(id)findWithType:(NSString *)type andQuery:(NSDictionary *)query{
    [self setFindQueryType:type];
    query = [self buildQueryWithQuery:query];
    
    // Run the query - $results = $this->getDataSource()->read($this, $query);
    NSArray *results = [self dataSourceReadWithQueryData:query];
    NSMutableArray *cResults = [[NSMutableArray alloc] init];
    for(NSDictionary *result in results){
        NSMutableDictionary *cResult = [[NSMutableDictionary alloc] init];
        for(NSString *field in [query objectForKey:@"fields"]){
            NSArray *modelColumnArray = [field componentsSeparatedByString:@"."];
            NSString *modelName = [modelColumnArray objectAtIndex:0];
            NSString *columnName = [modelColumnArray objectAtIndex:1];
            if([cResult objectForKey:modelName] == nil){
                [cResult setObject:[[NSMutableDictionary alloc] init] forKey:modelName];
            }
            [cResult setValue:[result objectForKey:columnName] forKeyPath:[NSString stringWithFormat:@"%@.%@", modelName, columnName]];
        }
        [cResults addObject:cResult];
    }
    // Return the data as HOT does
    if([type isEqualToString:@"all"]){
        return cResults;
    } else if([type isEqualToString:@"first"]){
        return [cResults objectAtIndex:0];
    }
    return nil;
}

/**
 * Builds the query array that is used by the data source to generate the query to fetch the data.
 */
-(NSDictionary *)buildQueryWithQuery:(NSDictionary *)query{
    // set the defaults
    NSMutableDictionary *defQuery = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                     [NSNull null], @"conditions",
                                     [[NSArray alloc] init], @"fields",
                                     [[NSMutableArray alloc] init], @"joins",
                                     [NSNumber numberWithInt:1], @"page",
                                     [NSNull null], @"group",
                                     nil];
    // merge the passed in query object
    NSArray *queryKeys =  [query allKeys];
    for(NSString *queryKey in queryKeys){
        [defQuery setObject:[query valueForKey:queryKey] forKey:queryKey];
    }
    
    [defQuery setValue:[self dataSourceFields:[defQuery valueForKey:@"fields"]] forKey:@"fields"];
    // Validate fields are of proper type
    // Validate page
    if(![[defQuery objectForKey:@"page"] isKindOfClass:[NSNumber class]]){
        // Try to type cast this to a class
        if([[defQuery objectForKey:@"page"] isKindOfClass:[NSString class]]){
            @try {
                [defQuery setValue:[NSNumber numberWithInt:[[defQuery objectForKey:@"page"] intValue]] forKeyPath:@"page"];
            }
            @catch (NSException *exception) {
                // Could not convert to number
                [defQuery setValue:[NSNumber numberWithInt:1] forKeyPath:@"page"];
            }
        } else {
            // not a nstring
            [defQuery setValue:[NSNumber numberWithInt:1] forKeyPath:@"page"];
        }
    }
    // Validate limit
    if([defQuery objectForKey:@"limit"] != nil){
        // Try to type cast this to a class
        if([[defQuery objectForKey:@"limit"] isKindOfClass:[NSString class]]){
            @try {
                [defQuery setValue:[NSNumber numberWithInt:[[defQuery objectForKey:@"limit"] intValue]] forKeyPath:@"limit"];
            }
            @catch (NSException *exception) {
                // Could not convert to number
                [defQuery setValue:[NSNumber numberWithInt:1] forKeyPath:@"limit"];
            }
        } else {
            // not a nstring
            [defQuery setValue:[NSNumber numberWithInt:1] forKeyPath:@"limit"];
        }
    }
    // set offset based on page - if ($query['page'] > 1 && !empty($query['limit'])) {
    if([(NSNumber *)[defQuery objectForKey:@"page"] intValue] > 1 && [defQuery objectForKey:@"limit"] != [NSNull null]){
        // calculate the offset - $query['offset'] = ($query['page'] - 1) * $query['limit'];
        int offset = ([(NSNumber *)[defQuery objectForKey:@"page"] intValue] - 1) * [(NSNumber *)[defQuery objectForKey:@"limit"] intValue];
        [defQuery setValue:[NSNumber numberWithInt:offset] forKey:@"offset"];
    }
    // set the order - if ($query['order'] === null && $this->order !== null) {
    if([defQuery valueForKey:@"order"] == [NSNull null] && [self order] != nil){
        if([[self order] isKindOfClass:[NSString class]]){
            [defQuery setValue:[[NSMutableArray alloc] initWithObjects:[self order], nil] forKey:@"order"];
        } else if ([[self order] isKindOfClass:[NSArray class]]){
            [defQuery setValue:[self order] forKey:@"order"];
        }
    }
    return defQuery;
}
/**
 * Initializes the model for writing a new record, loading the default values
 * for those fields that are not defined in $data, and clearing previous validation errors.
 * Especially helpful for saving data in loops.
 */
-(void)create{
    _inserting = true;
}
/**
 * Returns true if the supplied field exists in the model's database table.
 */
-(BOOL)hasField:(NSString *)field{
    NSDictionary *fields = [self schema];
    if([fields valueForKey:field] != nil){
        return YES;
    }
    return NO;
}
/**
 * Saves model data (based on white-list, if supplied) to the database. By
 * default, validation occurs before save.
 */
-(BOOL)saveWithData:(NSDictionary *)data{
    return [self saveWithData:data andValidate:YES andFieldList:[[NSArray alloc] init]];
}
/**
 * Saves model data (based on white-list, if supplied) to the database.
 */
-(BOOL)saveWithData:(NSDictionary *)data andValidate:(BOOL)validate andFieldList:(NSArray *)fieldList{
    // Check if the auto populated fields exist
    if([self hasField:@"modified"] && [data valueForKeyPath:[NSString stringWithFormat:@"%@.%@", _name, @"modified"]] == nil){
        [data setValue:[NSDate date] forKeyPath:[NSString stringWithFormat:@"%@.%@", _name, @"modified"]];
    }
    if([self hasField:@"updated"] && [data valueForKeyPath:[NSString stringWithFormat:@"%@.%@", _name, @"updated"]] == nil){
        [data setValue:[NSDate date] forKeyPath:[NSString stringWithFormat:@"%@.%@", _name, @"updated"]];
    }
    if(_inserting && [self hasField:@"created"] && [data valueForKeyPath:[NSString stringWithFormat:@"%@.%@", _name, @"created"]] == nil){
        [data setValue:[NSDate date] forKeyPath:[NSString stringWithFormat:@"%@.%@", _name, @"created"]];
    }
    // Perform data validation
    if(![self validatesData:data]){
        return false;
    }
    // Generate save sql
    NSString *sql;
    if(_inserting){
        sql = [self buildInsertStatementWithData:data];
    } else {
        sql = [self buildUpdateStatementWithData:data];
    }
    [self dataSourceExecuteWithSql:sql];
    return false;
}

-(BOOL)deleteWithQueryData:(NSDictionary *)queryData{
    NSString *sql = [self buildDeleteStatementWithData:queryData];
    [self dataSourceExecuteWithSql:sql];
    return YES;
}
/**
 * Validate the data that is being saved
 */
-(BOOL)validatesData:(NSDictionary *)data{
    // TODO: (Low) Support data validation
    return YES;
}

@end
