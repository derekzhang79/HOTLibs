//
//  HOTDatabase.h
//  HOTModel
//
//  Created by Jose Avila III on 11/21/12.
//  Copyright (c) 2012 Jose Avila III. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface HOTDatabase : NSObject {
    sqlite3 *_database;
    NSString *_path;
    int _openHandles;
    bool _pendingDbUpdate;
}

@property NSString *path;

-(id)initWithPath:(NSString *)path;

# pragma mark Open / close the database
-(sqlite3 *)openDatabase;
-(void)closeDatabase:(sqlite3 *)db;

# pragma mark Update the database at the location
-(void)updateDatabase:(NSString *)tmpPath;

@end
