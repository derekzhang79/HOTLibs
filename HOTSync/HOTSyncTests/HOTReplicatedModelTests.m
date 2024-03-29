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
    // Clear out previous changes
    HOTModel *change = [modelMgr modelWithName:@"Change"];
    NSString *sql = @"DELETE FROM changes WHERE 1";
    [change dataSourceExecuteWithSql:sql];
    // Set model
    HOTReplicatedModel *model = [[HOTReplicatedModel alloc] initWithModelManager:modelMgr];
    [model setTable:@"test"];
    [model setName:@"Test"];
    [model setPrimaryKeys:[[NSArray alloc] initWithObjects:@"col1", nil]];
    sql=@"CREATE TABLE test (col1 INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, col2 CHAR(25), col3 VARCHAR(25), col4 NUMERIC NOT NULL, col5 TEXT(25), UNIQUE (col2))";
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


# pragma mark Find Functions

-(void)testFindFirst{
    HOTModel *model = [self getModelTest];
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            [[NSDictionary alloc] initWithObjectsAndKeys:
                             @"1", @"Test.col1",
                             nil], @"conditions",
                            nil];
    NSDictionary *result = [model findWithType:@"first" andQuery:params];
    STAssertTrue(([[result valueForKeyPath:@"Test.col1"] intValue] == 1), @"Checking content of column 1");
    STAssertTrue([[result valueForKeyPath:@"Test.col2"] isEqualToString:@"test"], @"Checking content of column 2");
    STAssertTrue([[result valueForKeyPath:@"Test.col3"] isEqualToString:@"bla"], @"Checking content of column 3");
    STAssertTrue(([[result valueForKeyPath:@"Test.col4"] intValue] == 42), @"Checking content of column 4");
    STAssertTrue([[result valueForKeyPath:@"Test.col5"] isEqualToString:@"Some text data"], @"Checking content of column 5");
    return;
}

-(void)testFindAll{
    HOTModel *model = [self getModelTest];
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            [[NSDictionary alloc] initWithObjectsAndKeys:
                             @"1", @"Test.col1",
                             nil], @"conditions",
                            nil];
    NSArray *results = [model findWithType:@"all" andQuery:params];
    NSDictionary *result = [results objectAtIndex:0];
    STAssertTrue(([[result valueForKeyPath:@"Test.col1"] intValue] == 1), @"Checking content of column 1");
    STAssertTrue([[result valueForKeyPath:@"Test.col2"] isEqualToString:@"test"], @"Checking content of column 2");
    STAssertTrue([[result valueForKeyPath:@"Test.col3"] isEqualToString:@"bla"], @"Checking content of column 3");
    STAssertTrue(([[result valueForKeyPath:@"Test.col4"] intValue] == 42), @"Checking content of column 4");
    STAssertTrue([[result valueForKeyPath:@"Test.col5"] isEqualToString:@"Some text data"], @"Checking content of column 5");
    return;
}

-(void)testSaveLocalWithData{
    // Test
    HOTReplicatedModel *model = [self getModelTest];
    
    //
    NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                          [[NSDictionary alloc] initWithObjectsAndKeys:
                           [NSNumber numberWithInt:1], @"col1",
                           [NSNumber numberWithInt:1337], @"col4",
                           nil], @"Test",
                          nil];
    [model saveLocalWithData:data];
    
    // Find the
    NSArray *changes = [model findLocalChanges];
    STAssertEquals(1, (int)[changes count], @"Verifying count of localchanges is 1");
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            [[NSDictionary alloc] initWithObjectsAndKeys:
                             @"1", @"Test.col1",
                             nil], @"conditions",
                            nil];
    
    NSArray *results = [model findWithType:@"all" andQuery:params];
    NSDictionary *result = [results objectAtIndex:0];
    STAssertTrue(([[result valueForKeyPath:@"Test.col1"] intValue] == 1), @"Checking content of column 1");
    STAssertTrue([[result valueForKeyPath:@"Test.col2"] isEqualToString:@"test"], @"Checking content of column 2");
    STAssertTrue([[result valueForKeyPath:@"Test.col3"] isEqualToString:@"bla"], @"Checking content of column 3");
    STAssertTrue(([[result valueForKeyPath:@"Test.col4"] intValue] == 1337), @"Checking content of column 4");
    STAssertTrue([[result valueForKeyPath:@"Test.col5"] isEqualToString:@"Some text data"], @"Checking content of column 5");
    
}

@end
