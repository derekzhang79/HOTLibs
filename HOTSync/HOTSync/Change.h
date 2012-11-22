//
//  Change.h
//  HOTSync
//
//  Created by Jose Avila III on 10/27/12.
//  Copyright (c) 2012 Jose Avila III. All rights reserved.
//

#import "HOTReplicatedModel.h"

@class HOTSync;

@interface Change : HOTModel

-(id)initWithModelManager:(HOTModelManager *)modelMgr andSyncClinet:(HOTSync *)syncClient;

@end
