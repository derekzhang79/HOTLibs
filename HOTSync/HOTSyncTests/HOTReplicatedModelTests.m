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
    HOTSync *sync = [[HOTSync alloc] initWithModelManager:modelMgr andDataSource:@"default" andBaseURL:@"http://localhost/"];
    [sync setBaseURL:@"http://localhost/"];
    // Set model
    HOTReplicatedModel *model = [[HOTReplicatedModel alloc] initWithModelManager:modelMgr];
    [model setTable:@"test"];
    [model setName:@"Test"];
    [model setPrimaryKeys:[[NSArray alloc] initWithObjects:@"col1", nil]];
    NSString *sql=@"CREATE TABLE test (col1 INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, col2 CHAR(25), col3 VARCHAR(25), col4 NUMERIC NOT NULL, col5 TEXT(25), UNIQUE (col2))";
    [model dataSourceExecuteWithSql:sql];
    sql = @"INSERT INTO test VALUES (1, 'test', 'bla', 42, 'Some text data')";
    [model dataSourceExecuteWithSql:sql];
    return model;
}

-(void)testFindLocalChanges{
    HOTReplicatedModel *model = [self getModelTest];
    HOTModel *change = [[model modelManager] modelWithName:@"Change"];
    
    NSString *sql = @"DELETE FROM changes WHERE 1";
    [change dataSourceExecuteWithSql:sql];
    
    NSArray *changes = [model findLocalChanges];
    STAssertEquals(0, (int)[changes count], @"Verifying count of localchanges is 0");
    /*
    CREATE TABLE '%@' ( 
     'id' INTEGER PRIMARY KEY AUTOINCREMENT, 
     'remote_call_id' INTEGER NOT NULL ,
     'action' TEXT ,
     'model_name' TEXT not null,
     'primary_key1' TEXT,
     'primary_key2' TEXT,
     'data' TEXT )
     */
    // Insert the new local change
    sql = @"INSERT INTO changes VALUES ('1', '1', 'u', 'Test', '1', '', 'data')";
    [change dataSourceExecuteWithSql:sql];
    // Find the
    changes = [model findLocalChanges];
    STAssertEquals(1, (int)[changes count], @"Verifying count of localchanges is 0");
    
}


@end
