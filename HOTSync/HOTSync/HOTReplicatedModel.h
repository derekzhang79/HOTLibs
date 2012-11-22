//
//  HOTReplicatedModel.h
//  HOTSync
//
//  Created by Jose Avila III on 10/27/12.
//  Copyright (c) 2012 Jose Avila III. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HOTModel.h"
#import "HOTSync.h"
#import "utils.h"

@interface HOTReplicatedModel : CakeModel{
    HOTSync *_syncClient;
}

-(id)initWithModelManager:(CakeModelManager *)modelMgr andSyncClinet:(HOTSync *)syncClient;
-(BOOL)saveLocalWithData:(NSDictionary *)data;
-(BOOL)deleteLocalWithQueryData:(NSDictionary *)queryData;

@end
