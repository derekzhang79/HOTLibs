//
//  HOTModelTests.m
//  HOTModelTests
//
//  Created by Jose Avila III on 11/21/12.
//  Copyright (c) 2012 Jose Avila III. All rights reserved.
//

#import "HOTModelTests.h"

@implementation HOTModelTests


-(void)setUp{
    NSArray *savePaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSMutableString *savePath = [NSMutableString stringWithString:[savePaths objectAtIndex:0]];
    [savePath appendString:@"/test.sqlite3"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:savePath error:NULL];
}
-(HOTModel *)getModelTest{
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
    HOTModel *model = [[HOTModel alloc] initWithModelManager:modelMgr];
    [model setTable:@"test"];
    [model setName:@"Test"];
    [model setPrimaryKeys:[[NSArray alloc] initWithObjects:@"col1", nil]];
    NSString *sql=@"CREATE TABLE test (col1 INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, col2 CHAR(25), col3 VARCHAR(25), col4 NUMERIC NOT NULL, col5 TEXT(25), UNIQUE (col2))";
    [model dataSourceExecuteWithSql:sql];
    sql = @"INSERT INTO test VALUES (1, 'test', 'bla', 42, 'Some text data')";
    [model dataSourceExecuteWithSql:sql];
    return model;
}
-(void)testDataSourceExecuteWithSql{
    HOTModel *model = [self getModelTest];
    NSString *sql=@"PRAGMA user_version";
    [model dataSourceExecuteWithSql:sql];
}

# pragma mark schema detection

-(void)testSchema{
    HOTModel *model = [self getModelTest];
    NSDictionary *schema = [model schema];
    STAssertTrue([[schema valueForKeyPath:@"col1.name"] isEqualToString:@"col1"], @"Checking name of column detection");
    STAssertTrue([[[schema valueForKey:@"col1"] valueForKey:@"type"] isEqualToString:@"INTEGER"], @"Checking type of column detection");
    STAssertTrue(([[[schema valueForKey:@"col1"] valueForKey:@"nullable"] intValue]==0), @"Checking nullable of column detection");
    // Column 2
    STAssertTrue([[[schema valueForKey:@"col2"] valueForKey:@"name"] isEqualToString:@"col2"], @"Checking name of column detection");
    STAssertTrue([[[schema valueForKey:@"col2"] valueForKey:@"type"] isEqualToString:@"CHAR(25)"], @"Checking type of column detection");
    STAssertTrue(([[[schema valueForKey:@"col2"] valueForKey:@"nullable"] intValue]==1), @"Checking nullable of column detection");
}

-(void)testHasField{
    HOTModel *model = [self getModelTest];
    STAssertTrue([model hasField:@"col1"], @"Checking that fields are properly detected");
    STAssertFalse([model hasField:@"notacolumn"], @"Checking that fields are properly detected");
}

# pragma mark Select Statement Construction

-(void)testBuildStatementWithQueryData{
    HOTModel *model = [self getModelTest];
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            [[NSDictionary alloc] initWithObjectsAndKeys:
                             @"1", @"Test.col1",
                             nil], @"conditions",
                            nil];
    params = [model buildQueryWithQuery:params];
    NSString *sql = [model buildStatementWithQueryData:params];
    STAssertTrue([sql isEqualToString:@"SELECT Test.col4,Test.col2,Test.col5,Test.col3,Test.col1 FROM test as Test WHERE Test.col1='1'"], @"Validating proper sql creation");
}

-(void)testBuildStatementWithQueryDataFields{
    HOTModel *model = [self getModelTest];
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            [[NSDictionary alloc] initWithObjectsAndKeys:
                             @"1", @"Test.col1",
                             nil], @"conditions",
                            [[NSArray alloc] initWithObjects:
                             @"Test.col1",
                             @"Test.col3",
                             nil], @"fields",
                            nil];
    params = [model buildQueryWithQuery:params];
    NSString *sql = [model buildStatementWithQueryData:params];
    STAssertTrue([sql isEqualToString:@"SELECT Test.col1,Test.col3 FROM test as Test WHERE Test.col1='1'"], @"Validating proper sql creation");
}
-(void)testBuildStatementWithQueryDataFieldWildcard{
    HOTModel *model = [self getModelTest];
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            [[NSDictionary alloc] initWithObjectsAndKeys:
                             @"1", @"Test.col1",
                             nil], @"conditions",
                            [[NSArray alloc] initWithObjects:
                             @"Test.*",
                             nil], @"fields",
                            nil];
    params = [model buildQueryWithQuery:params];
    NSString *sql = [model buildStatementWithQueryData:params];
    STAssertTrue([sql isEqualToString:@"SELECT Test.col4,Test.col2,Test.col5,Test.col3,Test.col1 FROM test as Test WHERE Test.col1='1'"], @"Validating proper sql creation");
}

-(void)testBuildStatementWithQueryDataLikeConditions{
    HOTModel *model = [self getModelTest];
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            [[NSDictionary alloc] initWithObjectsAndKeys:
                             @"1%", @"Test.col1 like",
                             nil], @"conditions",
                            [[NSArray alloc] initWithObjects:
                             @"Test.col2",
                             nil], @"fields",
                            nil];
    params = [model buildQueryWithQuery:params];
    NSString *sql = [model buildStatementWithQueryData:params];
    STAssertTrue([sql isEqualToString:@"SELECT Test.col2 FROM test as Test WHERE Test.col1 like '1%'"], @"Validating proper sql creation");
}

-(void)testBuildStatementWithQueryDataNullConditions{
    HOTModel *model = [self getModelTest];
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            [[NSDictionary alloc] initWithObjectsAndKeys:
                             @"", @"Test.col1 is null",
                             nil], @"conditions",
                            [[NSArray alloc] initWithObjects:
                             @"Test.col2",
                             nil], @"fields",
                            nil];
    params = [model buildQueryWithQuery:params];
    NSString *sql = [model buildStatementWithQueryData:params];
    STAssertTrue([sql isEqualToString:@"SELECT Test.col2 FROM test as Test WHERE Test.col1 is null"], @"Validating proper sql creation");
}

-(void)testBuildStatementWithQueryDataOrConditions{
    HOTModel *model = [self getModelTest];
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            [[NSDictionary alloc] initWithObjectsAndKeys:
                             [[NSDictionary alloc] initWithObjectsAndKeys:
                              @"", @"Test.col1 is null",
                              @"1", @"Test.col1",
                              nil], @"or",
                             nil], @"conditions",
                            [[NSArray alloc] initWithObjects:
                             @"Test.col2",
                             nil], @"fields",
                            nil];
    params = [model buildQueryWithQuery:params];
    NSString *sql = [model buildStatementWithQueryData:params];
    STAssertTrue([sql isEqualToString:@"SELECT Test.col2 FROM test as Test WHERE (Test.col1 is null OR Test.col1='1')"], @"Validating proper sql creation");
}

-(void)testBuildStatementJoinsWithQueryData{
    HOTModel *model = [self getModelTest];
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            [[NSDictionary alloc] initWithObjectsAndKeys:
                             @"1%", @"Test.col1 like",
                             nil], @"conditions",
                            [[NSArray alloc] initWithObjects:
                             @"Test.col2",
                             nil], @"fields",
                            [[NSArray alloc] initWithObjects:
                             [[NSDictionary alloc] initWithObjectsAndKeys:
                              @"channels", @"table",
                              @"Channel", @"alias",
                              @"LEFT", @"type",
                              [[NSArray alloc] initWithObjects:
                               @"Channel.id = Item.channel_id",
                               nil], @"conditions",
                              nil],
                             nil], @"joins",
                            nil];
    params = [model buildQueryWithQuery:params];
    NSString *sql = [model buildStatementWithQueryData:params];
    STAssertTrue([sql isEqualToString:@"SELECT Test.col2 FROM test as Test LEFT JOIN channels AS Channel ON Channel.id = Item.channel_id WHERE Test.col1 like '1%'"], @"Validating proper sql creation");
}


# pragma mark Insert Statement Consruction

-(void)testBuildInsertStatementWithData{
    
    HOTModel *model = [self getModelTest];
    NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                          [[NSDictionary alloc] initWithObjectsAndKeys:
                           [NSNumber numberWithInt:2], @"col1",
                           @"data2", @"col2",
                           nil], @"Test",
                          nil];
    NSString *sql = [model buildInsertStatementWithData:data];
    STAssertTrue([sql isEqualToString:@"INSERT INTO test (col2,col1) VALUES ('data2',2)"], @"Verifying insert SQL generation");
    
}

# pragma mark Update Statement Consruction

-(void)testBuildUpdateStatementWithData{
    
    HOTModel *model = [self getModelTest];
    NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                          [[NSDictionary alloc] initWithObjectsAndKeys:
                           [NSNumber numberWithInt:2], @"col1",
                           @"data2", @"col2",
                           [NSNumber numberWithInt:35], @"col4",
                           nil], @"Test",
                          nil];
    NSString *sql = [model buildUpdateStatementWithData:data];
    STAssertTrue([sql isEqualToString:@"UPDATE test SET col2='data2',col4=35 WHERE col1=2"], @"Verifying insert SQL generation");
}

# pragma mark Delete Statement Consruction

-(void)testBuildDeleteStatementWithData{
    
    HOTModel *model = [self getModelTest];
    NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                          [[NSDictionary alloc] initWithObjectsAndKeys:
                           @"data2", @"Test.col2",
                           [NSNumber numberWithInt:35], @"Test.col4",
                           nil], @"conditions",
                          nil];
    NSString *sql = [model buildDeleteStatementWithData:data];
    STAssertTrue([sql isEqualToString:@"DELETE FROM test WHERE col4=35 AND col2='data2'"], @"Verifying insert SQL generation");
    
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

# pragma mark Insert Functions

-(void)testInsertData{
    HOTModel *model = [self getModelTest];
    NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                          [[NSDictionary alloc] initWithObjectsAndKeys:
                           [NSNumber numberWithInt:69], @"col4",
                           nil], @"Test",
                          nil];
    [model setInserting:YES];
    [model saveWithData:data];
    NSNumber *insertedId = [model insertedId];
    STAssertTrue(([insertedId intValue] == 2), @"Verifying the record got inserted and with an updated auto incremented value");
    // Verify data got inserted properly
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            [[NSDictionary alloc] initWithObjectsAndKeys:
                             insertedId, @"Test.col1",
                             nil], @"conditions",
                            nil];
    NSArray *results = [model findWithType:@"all" andQuery:params];
    NSDictionary *result = [results objectAtIndex:0];
    STAssertTrue(([[result valueForKeyPath:@"Test.col1"] intValue] == [insertedId intValue]), @"Checking content of column 1");
    STAssertTrue(([[result valueForKeyPath:@"Test.col4"] intValue] == 69), @"Checking content of column 4");
    return;
}

# pragma mark Update Functions

-(void)testUpdateData{
    HOTModel *model = [self getModelTest];
    NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                          [[NSDictionary alloc] initWithObjectsAndKeys:
                           [NSNumber numberWithInt:69], @"col4",
                           nil], @"Test",
                          nil];
    [model setInserting:YES];
    [model saveWithData:data];
    NSNumber *insertedId = [model insertedId];
    STAssertTrue(([insertedId intValue] == 2), @"Verifying the record got inserted and with an updated auto incremented value");
    
    data = [[NSDictionary alloc] initWithObjectsAndKeys:
            [[NSDictionary alloc] initWithObjectsAndKeys:
             [NSNumber numberWithInt:32], @"col4",
             insertedId, @"col1",
             nil], @"Test",
            nil];
    [model setInserting:NO];
    [model saveWithData:data];
    
    // Verify data got inserted properly
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            [[NSDictionary alloc] initWithObjectsAndKeys:
                             insertedId, @"Test.col1",
                             nil], @"conditions",
                            nil];
    NSArray *results = [model findWithType:@"all" andQuery:params];
    NSDictionary *result = [results objectAtIndex:0];
    STAssertTrue(([[result valueForKeyPath:@"Test.col1"] intValue] == [insertedId intValue]), @"Checking content of column 1");
    STAssertTrue(([[result valueForKeyPath:@"Test.col4"] intValue] == 32), @"Checking content of column 4");
    return;
}

# pragma mark Delete Functions

-(void)testDeleteData{
    HOTModel *model = [self getModelTest];
    
    // verify the record exists first
    NSDictionary *fparams = [[NSDictionary alloc] initWithObjectsAndKeys:
                             [[NSDictionary alloc] initWithObjectsAndKeys:
                              @"1", @"Test.col1",
                              nil], @"conditions",
                             nil];
    NSArray *results = [model findWithType:@"all" andQuery:fparams];
    STAssertEquals((int)[results count], 1, @"Verifying the record exists initially");
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            [[NSDictionary alloc] initWithObjectsAndKeys:
                             @"1", @"Test.col1",
                             nil], @"conditions",
                            nil];
    [model deleteWithQueryData:params];
    
    results = [model findWithType:@"all" andQuery:params];
    STAssertEquals((int)[results count], 0, @"Verifying the record got deleted");
    
    
    
}

@end
