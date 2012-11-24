//
//  HOTSync.h
//  HOTSync
//
//  Created by Jose Avila III on 10/26/12.
//  Copyright (c) 2012 Jose Avila III. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RemoteCall.h"
#import "Change.h"

@interface HOTSync : NSObject {
    /**
     * Variables that describe the upstream api
     */
    NSString *_baseURL;
    /**
     * Variables that describe the api 
     */
    NSString *_deviceId;
    NSString *_deviceModel;
    NSString *_deviceName;
    NSString *_deviceSystemName;
    NSString *_deviceSystemVersion;
    /**
     * Other shit
     */
    NSString *_apiVersion;
    NSString *_datasource; // The datasource you are syncing
    int _transactionId; // Defines how far into the transaction log we are
    bool _syncing; // Definies if syncing threads should be running at this time
    bool _downloadingSnapshot; // Specifies the fact that a snapshot is being downloaded
    NSDate *_fullSyncDateDownstream;
    NSDate *_fullSyncDateUpstream;
    HOTModelManager *_modelManager;
}

@property (strong) NSString *baseURL;
@property (strong) NSString *deviceId;
@property (strong) HOTModelManager *modelManager;

-(id)initWithModelManager:(HOTModelManager *)modelMgr andDataSource:(NSString *)datasource andBaseURL:(NSString *)baseUrl;
-(int)transactionId;
-(NSMutableURLRequest *)getApiRequestWithUrl:(NSString *)url;
-(void)syncTransactions:(NSArray *)transactions;
-(BOOL)syncTransaction:(NSDictionary *)transaction;

@end

