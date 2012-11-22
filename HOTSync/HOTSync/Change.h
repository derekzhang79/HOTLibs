//
//  Change.h
//  HOTSync
//
//  Created by Jose Avila III on 10/27/12.
//  Copyright (c) 2012 Jose Avila III. All rights reserved.
//

#import "HOTReplicatedModel.h"

@interface Change : CakeModel


-(id)initWithModelManager:(CakeModelManager *)modelMgr andSyncClinet:(HOTSync *)syncClient;

@end
