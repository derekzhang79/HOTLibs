//
//  HOTInflectorTests.m
//  HOTModel
//
//  Created by Jose Avila III on 11/21/12.
//  Copyright (c) 2012 Jose Avila III. All rights reserved.
//

#import "HOTInflectorTests.h"

@implementation HOTInflectorTests

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

- (void)testUnderscoreCamelCaseWord
{
    NSString *underscored = [HOTInflector underscoreCamelCaseWord:@"TestWord"];
    STAssertTrue([underscored isEqualToString:@"test_word"], @"Underscoring TestWord to test_word");
}

-(void)testPluralizeWordRules{
    NSString *final = [HOTInflector pluralizeWord:@"virus"];
    STAssertTrue([final isEqualToString:@"viri"], @"Pluralizing virus to viri");
}
-(void)testPluralizeWordUninflected{
    NSString *final = [HOTInflector pluralizeWord:@"deer"];
    STAssertTrue([final isEqualToString:@"deer"], @"Pluralizing uninflected deer to deer");
}
-(void)testPluralizeWordIrregular{
    NSString *final = [HOTInflector pluralizeWord:@"atlas"];
    STAssertTrue([final isEqualToString:@"atlases"], @"Pluralizing irregular atlas to atlases");
}

@end
