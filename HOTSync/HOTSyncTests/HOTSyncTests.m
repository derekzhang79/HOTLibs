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

- (void)testGetApiRequestWithUrl
{
    // Set up the test database
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
    NSURLRequest *request = [sync getApiRequestWithUrl:@"URL"];
    STAssertNotNil([request valueForHTTPHeaderField:@"X-HotSync-DeviceId"], @"Verifying DeviceId header is set");
    STAssertNotNil([request valueForHTTPHeaderField:@"X-HotSync-DeviceModel"], @"Verifying DeviceModel header is set");
    STAssertNotNil([request valueForHTTPHeaderField:@"X-HotSync-DeviceName"], @"Verifying DeviceName header is set");
    STAssertNotNil([request valueForHTTPHeaderField:@"X-HotSync-DeviceSystemName"], @"Verifying DeviceSystemName header is set");
    STAssertNotNil([request valueForHTTPHeaderField:@"X-HotSync-DeviceSystemVersion"], @"Verifying DeviceSystemVersion header is set");
    STAssertNotNil([request valueForHTTPHeaderField:@"X-HotSync-ApiVersion"], @"Verifying ApiVersion header is set");
    STAssertTrue([[[request URL] absoluteString] isEqualToString:@"http://localhost/test/URL"], @"Verifyig URL (%@) is corect", [[request URL] absoluteString]);
}

@end
