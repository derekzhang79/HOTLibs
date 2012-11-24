//
//  HOTReplicatedModel.h
//  HOTSync
//
//  Created by Jose Avila III on 10/27/12.
//  Copyright (c) 2012 Jose Avila III. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HOTSync.h"

@class HOTSync;

@interface HOTReplicatedModel : HOTModel{
    HOTSync *_syncClient;
}

-(id)initWithModelManager:(HOTModelManager *)modelMgr andSyncClinet:(HOTSync *)syncClient;
-(BOOL)saveLocalWithData:(NSDictionary *)data;
-(BOOL)deleteLocalWithQueryData:(NSDictionary *)queryData;
-(HOTModel *)HOTModel;

@end
