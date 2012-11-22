//
//  HOTDatabase.m
//  HOTModel
//
//  Created by Jose Avila III on 11/21/12.
//  Copyright (c) 2012 Jose Avila III. All rights reserved.
//

#import "HOTDatabase.h"

@implementation HOTDatabase

-(id)initWithPath:(NSString *)path{
    self = [super init];
    if (self) {
        // Initialization code here.
        _path = path;
        _pendingDbUpdate = NO;
        _openHandles = 0;
    }
    return self;
}

# pragma mark Open / close the database

/**
 * Open the database
 */
-(sqlite3 *)openDatabase{
    // Block opening until we have created the database.
    while (_pendingDbUpdate) {
        [NSThread sleepForTimeInterval:.1];
    }
    // Give them the database
    sqlite3 *db;
    if(sqlite3_open_v2([_path UTF8String], &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL) != SQLITE_OK){
        NSLog(@"ERROR: %@", [NSString stringWithUTF8String:sqlite3_errmsg(db)]);
        return nil;
    }
    _openHandles++;
    return db;
}

/**
 * Close the database
 */
-(void)closeDatabase:(sqlite3 *)db{
    _openHandles--;
    sqlite3_close(db);
}

# pragma mark Update the database at the location
/**
 * Replaces the old database with a new one.
 */
-(void)updateDatabase:(NSString *)tmpPath{
    _pendingDbUpdate = YES;
    while(_openHandles != 0){
        [NSThread sleepForTimeInterval:.1];
    }
    
    // We can now update the database
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager moveItemAtPath:tmpPath toPath:_path error:nil];
    
    // Reset pending db update as it was done
    _pendingDbUpdate = NO;
}

@end
