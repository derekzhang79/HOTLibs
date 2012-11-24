//
//  HOTSyncTests.m
//  HOTSyncTests
//
//  Created by Jose Avila III on 11/21/12.
//  Copyright (c) 2012 Jose Avila III. All rights reserved.
//

#import "HOTSyncTests.h"

@implementation HOTSyncTests

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

-(HOTSync *)getHotSync{
    // Set up the test daatapse
    
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
    // Run the test here
    HOTModelManager *modelMgr = [[HOTModelManager alloc] initWithConfig:config];
    HOTSync *sync = [[HOTSync alloc] initWithModelManager:modelMgr andDataSource:@"default" andBaseURL:@"http://localhost/test/"];
    
    // Set up the model
    HOTReplicatedModel *model = [[HOTReplicatedModel alloc] initWithModelManager:modelMgr];
    [model setTable:@"test"];
    [model setName:@"Test"];
    [model setPrimaryKeys:[[NSArray alloc] initWithObjects:@"col1", nil]];
    NSString *sql=@"CREATE TABLE test (col1 INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, col2 CHAR(25), col3 VARCHAR(25), col4 NUMERIC NOT NULL, col5 TEXT(25), UNIQUE (col2))";
    [model dataSourceExecuteWithSql:sql];
    sql = @"INSERT INTO test VALUES (1, 'test', 'bla', 42, 'Some text data')";
    [model dataSourceExecuteWithSql:sql];
    [modelMgr registerModel:model];
    
    return sync;
}
- (void)testGetApiRequestWithUrl
{
    // Set up the test database
    HOTSync *sync = [self getHotSync];
    NSURLRequest *request = [sync getApiRequestWithUrl:@"URL"];
    STAssertNotNil([request valueForHTTPHeaderField:@"X-HotSync-DeviceId"], @"Verifying DeviceId header is set");
    STAssertNotNil([request valueForHTTPHeaderField:@"X-HotSync-DeviceModel"], @"Verifying DeviceModel header is set");
    STAssertNotNil([request valueForHTTPHeaderField:@"X-HotSync-DeviceName"], @"Verifying DeviceName header is set");
    STAssertNotNil([request valueForHTTPHeaderField:@"X-HotSync-DeviceSystemName"], @"Verifying DeviceSystemName header is set");
    STAssertNotNil([request valueForHTTPHeaderField:@"X-HotSync-DeviceSystemVersion"], @"Verifying DeviceSystemVersion header is set");
    STAssertNotNil([request valueForHTTPHeaderField:@"X-HotSync-ApiVersion"], @"Verifying ApiVersion header is set");
    STAssertTrue([[[request URL] absoluteString] isEqualToString:@"http://localhost/test/URL"], @"Verifyig URL (%@) is corect", [[request URL] absoluteString]);
}

#pragma mark Test Syncing Transactions

-(void)testSyncTransactionInsert{
    HOTSync *sync = [self getHotSync];
    // Make sure the data is not in the database yet:
    
    HOTModel *model = [(HOTReplicatedModel *)[[sync modelManager] modelWithName:@"Test"] HOTModel];
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            [[NSDictionary alloc] initWithObjectsAndKeys:
                             @"123", @"Test.col1",
                             nil], @"conditions",
                            nil];
    NSDictionary *result = [model findWithType:@"first" andQuery:params];
    STAssertNil(result, @"Verifying the record is not in the database yet");
    // Add the record to the database
    NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                          @"Test", @"model_name",
                          @"I", @"action",
                          @"123", @"primary_key",
                          [[NSDictionary alloc] initWithObjectsAndKeys:
                           @"123", @"col1",
                           @"4", @"col4",
                           nil], @"data",
                          nil];
    bool ret = [sync syncTransaction:data];
    STAssertTrue(ret, @"Asserting transaction was synced properly");
    // Find the newly inserted record
    result = [model findWithType:@"first" andQuery:params];
    STAssertTrue(([[result valueForKeyPath:@"Test.col1"] intValue] == 123), @"Checking content of column 1");
    STAssertTrue(([[result valueForKeyPath:@"Test.col4"] intValue] == 4), @"Checking content of column 4");
}

-(void)testSyncTransactionUpdate{
    HOTSync *sync = [self getHotSync];
    // Make sure the data is not in the database yet:
    
    HOTModel *model = [(HOTReplicatedModel *)[[sync modelManager] modelWithName:@"Test"] HOTModel];
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            [[NSDictionary alloc] initWithObjectsAndKeys:
                             @"1", @"Test.col1",
                             nil], @"conditions",
                            nil];
    NSDictionary *result = [model findWithType:@"first" andQuery:params];
    STAssertNotNil(result, @"Verifying the record is in the database");
    STAssertTrue(([[result valueForKeyPath:@"Test.col4"] intValue] == 42), @"Checking content of column 4");
    // Add the record to the database
    NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                          @"Test", @"model_name",
                          @"U", @"action",
                          @"1", @"primary_key",
                          [[NSDictionary alloc] initWithObjectsAndKeys:
                           @"1", @"col1",
                           @"4", @"col4",
                           nil], @"data",
                          nil];
    bool ret = [sync syncTransaction:data];
    STAssertTrue(ret, @"Asserting transaction was synced properly");
    // Find the newly inserted record
    result = [model findWithType:@"first" andQuery:params];
    STAssertTrue(([[result valueForKeyPath:@"Test.col1"] intValue] == 1), @"Checking content of column 1");
    STAssertTrue(([[result valueForKeyPath:@"Test.col4"] intValue] == 4), @"Checking content of column 4");
}

-(void)testSyncTransactionDelete{
    HOTSync *sync = [self getHotSync];
    // Make sure the data is not in the database yet:
    
    HOTModel *model = [(HOTReplicatedModel *)[[sync modelManager] modelWithName:@"Test"] HOTModel];
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            [[NSDictionary alloc] initWithObjectsAndKeys:
                             @"1", @"Test.col1",
                             nil], @"conditions",
                            nil];
    NSDictionary *result = [model findWithType:@"first" andQuery:params];
    STAssertNotNil(result, @"Verifying the record is in the database");
    STAssertTrue(([[result valueForKeyPath:@"Test.col4"] intValue] == 42), @"Checking content of column 4");
    // Add the record to the database
    NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                          @"Test", @"model_name",
                          @"D", @"action",
                          @"1", @"primary_key",
                          [[NSDictionary alloc] initWithObjectsAndKeys:
                           @"1", @"col1",
                           nil], @"data",
                          nil];
    bool ret = [sync syncTransaction:data];
    STAssertTrue(ret, @"Asserting transaction was synced properly");
    // Find the newly inserted record
    result = [model findWithType:@"first" andQuery:params];
    STAssertNil(result, @"Verifying the record is not in the database");
}

-(void)testSyncTransactions{
    HOTSync *sync = [self getHotSync];
    // Make sure the data is not in the database yet:
    
    HOTModel *model = [(HOTReplicatedModel *)[[sync modelManager] modelWithName:@"Test"] HOTModel];
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            [[NSDictionary alloc] initWithObjectsAndKeys:
                             @"123", @"Test.col1",
                             nil], @"conditions",
                            nil];
    NSDictionary *result = [model findWithType:@"first" andQuery:params];
    STAssertNil(result, @"Verifying the record is not in the database yet");
    // Add the record to the database
    NSArray *data = [[NSArray alloc] initWithObjects:
                     [[NSDictionary alloc] initWithObjectsAndKeys:
                      @"Test", @"model_name",
                      @"I", @"action",
                      @"123", @"primary_key",
                      @"1337", @"id",
                      [[NSDictionary alloc] initWithObjectsAndKeys:
                       @"123", @"col1",
                       @"4", @"col4",
                       nil], @"data",
                      nil],
                     nil];
    [sync syncTransactions:data];
    // Find the newly inserted record
    result = [model findWithType:@"first" andQuery:params];
    STAssertTrue(([[result valueForKeyPath:@"Test.col1"] intValue] == 123), @"Checking content of column 1");
    STAssertTrue(([[result valueForKeyPath:@"Test.col4"] intValue] == 4), @"Checking content of column 4");
    STAssertEquals(1337, [sync transactionId], @"Verifying the transaction ID properly got updated");
}

-(void)testSyncDownstream{
    
}

@end
