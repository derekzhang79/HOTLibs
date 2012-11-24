//
//  HOTReplicatedModelTests.m
//  HOTSync
//
//  Created by Jose Avila III on 11/23/12.
//  Copyright (c) 2012 Jose Avila III. All rights reserved.
//

#import "HOTReplicatedModelTests.h"

@implementation HOTReplicatedModelTests

- (void)setUp
{
    [super setUp];
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    [super tearDown];
}

-(HOTReplicatedModel *)getModelTest{
    // TODO: Select distinct
    
    NSArray *savePaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSMutableString *savePath = [NSMutableString stringWithString:[savePaths objectAtIndex:0]];
    [savePath appendString:@"/test.sqlite3"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:savePath error:NULL];
    NSDictionary *config = [[NSDictionary alloc] initWithObjectsAndKeys:
                            [[NSDictionary alloc] initWithObjectsAndKeys:
                             savePath, @"Path",
                             nil], @"default",
                            nil];
    
    HOTModelManager *modelMgr = [[HOTModelManager alloc] initWithConfig:config];
    
    // Set model
    HOTModel *model = [[HOTModel alloc] initWithModelManager:modelMgr];
    [model setTable:@"test"];
    [model setName:@"Test"];
    [model setPrimaryKeys:[[NSArray alloc] initWithObjects:@"col1", nil]];
    // Set Replicated
    HOTReplicatedModel *repModel = [[HOTReplicatedModel alloc] initWithModelManager:modelMgr];
    [repModel setTable:@"test"];
    [repModel setName:@"Test"];
    [repModel setPrimaryKeys:[[NSArray alloc] initWithObjects:@"col1", nil]];
    NSString *sql=@"CREATE TABLE test (col1 INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, col2 CHAR(25), col3 VARCHAR(25), col4 NUMERIC NOT NULL, col5 TEXT(25), UNIQUE (col2))";
    [model dataSourceExecuteWithSql:sql];
    sql = @"INSERT INTO test VALUES (1, 'test', 'bla', 42, 'Some text data')";
    [model dataSourceExecuteWithSql:sql];
    return repModel;
}


@end
