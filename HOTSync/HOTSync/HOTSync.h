//
//  HOTSync.h
//  HOTSync
//
//  Created by Jose Avila III on 10/26/12.
//  Copyright (c) 2012 Jose Avila III. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HOTModel.h"
#import "utils.h"
#import "RemoteCall.h"
#import "Change.h"

@protocol HOTSyncDelegate <NSObject>
@required
- (void) processSuccessful: (BOOL)success;
@end


@interface HOTSync : NSObject {
    NSString *_baseURL;
    NSString *_deviceType;
    NSString *_deviceId;
    NSString *_apiVersion;
    NSString *_datasource; // The datasource you are syncing
    int _transactionId; // Defines how far into the transaction log we are
    bool _syncing; // Definies if syncing threads should be running at this time
    bool _downloadingSnapshot; // Specifies the fact that a snapshot is being downloaded
    NSDate *_fullSyncDateDownstream;
    NSDate *_fullSyncDateUpstream;
    CakeModelManager *_modelManager;
}

@property (strong) NSString *baseURL;
@property (strong) NSString *deviceType;
@property (strong) NSString *deviceId;
@property (assign) int transactionId;

@end
