//
//  HOTSync.m
//  HOTSync
//
//  Created by Jose Avila III on 10/26/12.
//  Copyright (c) 2012 Jose Avila III. All rights reserved.
//

#import "HOTSync.h"

@implementation HOTSync

-(id)initWithModelManager:(CakeModelManager *)modelMgr andDataSource:(NSString *)datasource andBaseURL:(NSString *)baseUrl andDeviceType:(NSString *)deviceType andDeviceId:(NSString *)deviceId{
    self = [super init];
    if(self){
        _modelManager = modelMgr;
        _datasource = datasource;
        _baseURL = baseUrl;
        _deviceId = deviceId;
        _deviceType = deviceType;
        _apiVersion = @"2.0";
        // Add the local datasource associated with this datasource
        NSString *path = [NSString stringWithFormat:@"%@.local", [[_modelManager getDatabaseWithDatasource:datasource] path]];
        NSDictionary *config = [[NSDictionary alloc] initWithObjectsAndKeys:
                                path, @"Path",
                                nil];
        [_modelManager addDatasorceWithName:@"local" andConfig:config];
        // add the 2 datasource methods
        [_modelManager registerModel:[[RemoteCall alloc] initWithModelManager:modelMgr andSyncClinet:self]];
        [_modelManager registerModel:[[Change alloc] initWithModelManager:modelMgr andSyncClinet:self]];
    }
    return self;
}

# pragma mark Sync Date management

-(void)setFullSyncDateUpstream:(NSDate *)date{
    _fullSyncDateUpstream = date;
}

-(void)setFullSyncDateDownstream:(NSDate *)date{
    _fullSyncDateDownstream = date;
}

# pragma mark API Request Building
-(NSMutableURLRequest *)getApiRequestWithUrl:(NSString *)url{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:5];
    [request setValue:_deviceId forHTTPHeaderField:@"X-HotSync-DeviceUUID"];
    [request setValue:_deviceType forHTTPHeaderField:@"X-HOTSync-Type"];
    [request setValue:_apiVersion forHTTPHeaderField:@"X-HOTSync-Version"];
    return request;
}


# pragma mark Threaded syncing

-(void)startSyncThreads{
    _syncing = YES;
    [NSThread detachNewThreadSelector:@selector(syncDownstreamThread) toTarget:self withObject:nil];
    [NSThread detachNewThreadSelector:@selector(syncUpstreamThread) toTarget:self withObject:nil];
}

-(void)stopSyncThreads{
    _syncing = NO;
}

# pragma mark Threaded Downstream syncing

-(void)syncDownstreamThread{
    while(1){
        // NEVER END THIS THREAD - Unless told to stop
        if(!_syncing){
            NSLog(@"Shutting down downstream thread");
            break;
        }
        // Sync data downsteam as fast as possible until you are up to date.
        [self syncDownstreamUpToDate];
        // sleep for a small period to not slam the servers
        [NSThread sleepForTimeInterval:30];
    }
}

/**
 *
 */
-(void)downloadSnapshot:(NSDictionary *)data{
    // Need to alculate the time it takes to download the snapshot here
    CakeDatabase *database = [_modelManager getDatabaseWithDatasource:_datasource];
    NSString *snapshotFile = [data objectForKey:@"snapshot_file"];
    // download the snapshot file and save it to a temporary location
    NSData *snapshot = [NSData dataWithContentsOfURL:[NSURL URLWithString:snapshotFile]];
    [snapshot writeToFile:[NSString stringWithFormat:@"%@.tmp", [database path]] atomically:NO];
    // Replace the old database with the new one.
    [database updateDatabase:[NSString stringWithFormat:@"%@.tmp", [database path]]];
}
/*
 * Syncs data down until things are up to date
 */
-(void)syncDownstreamUpToDate{
    while(1){
        @try {
            NSLog(@"ONZRAReplicationClient: syncing from the transactionid %d", _transactionId);
            NSString *fullUrl = [[NSString alloc] initWithFormat:@"%@/api/sync/sync/%d.json", _baseURL, _transactionId];
            
            NSLog(@"HTTP REQUEST: %@", fullUrl);
            NSURLRequest *request = [self getApiRequestWithUrl:fullUrl];
            NSError *error;
            NSURLResponse *response;
            NSData *returndata = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            if(returndata){
                [self setFullSyncDateDownstream:[NSDate date]];
                // if there was not an error getting the data.
                NSString *returnString = [[NSString alloc] initWithData:returndata encoding:NSUTF8StringEncoding];
                NSLog(@"Got Status Code: %d",[((NSHTTPURLResponse *)response) statusCode]);
                if([((NSHTTPURLResponse *)response) statusCode] != 200){
                    // This may be telling you to grab a snapshot
                    NSDictionary *returnObject = [NSJSONSerialization JSONObjectWithData:[returnString dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
                    if(returnObject && [returnObject isKindOfClass:[NSDictionary class]] && [[returnObject objectForKey:@"code"] intValue] == 1){
                        // you are being told to grab a snapshot.
                        [self downloadSnapshot:[returnObject objectForKey:@"data"]];
                        continue;
                    } else {
                        NSLog(@"HTTP RESPONSE: %@",returnString);
                        @throw [NSException exceptionWithName: @"ApiError"
                                                       reason: @"An exception occurred while trying to sync data downstream"
                                                     userInfo: nil];
                    }
                }
                // Check to see if we need to download a snapshot
                NSArray *returnObject = [NSJSONSerialization JSONObjectWithData:[returnString dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
                // Sync transactions
                if([returnObject count] != 0){
                    [self syncTransactions:returnObject];
                    // Continue will skip to the loop again without sleeping as there may be more updates
                    continue;
                }
            }
            // At this point we should be done processing and up to date
            return;
        }
        @catch (NSException *exception) {
            NSLog(@"Error %@ - %@", [exception name], [exception reason]);
            // There may have been a connection issue. return and let the parent thread manage coming back to this operation.
            return;
        }
    }
}

#pragma mark Threaded upstream syncing

-(void)syncUpstreamThread{
    while(1){
        // NEVER END THIS THREAD - Unless told to stop
        if(!_syncing){
            NSLog(@"Shutting down upstream thread");
            break;
        }
        @try {
            NSArray *results = [[_modelManager modelWithName:@"RemoteCall"] findWithType:@"all" andQuery:[[NSDictionary alloc] init]];
            NSLog(@"ONZRAReplicationClient: Attempting to sync %d changes upstream", [results count]);
            if ([results count] == 0){
                [self setFullSyncDateUpstream:[NSDate date]];
            }
            for(NSDictionary *result in results){
                // Call API server
                NSLog(@"Got Result: %@", [NSJSONSerialization stringWithJSONObject:result options:NSJSONWritingPrettyPrinted error:nil]);
                // Call upstream api method
                NSString *fullUrl = [[NSString alloc] initWithFormat:@"%@/api/%@.json", _baseURL, [[result objectForKey:@"RemoteCall"] objectForKey:@"method"]];
                NSLog(@"HTTP REQUEST: %@", fullUrl);
                NSMutableURLRequest *request = [self getApiRequestWithUrl:fullUrl];
                [request setHTTPMethod:@"POST"];
                [request setHTTPBody:[[[result objectForKey:@"RemoteCall"] objectForKey:@"post_data"] dataUsingEncoding:NSUTF8StringEncoding]];
                NSError *error;
                NSURLResponse *response;
                NSData *returndata = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
                // Tell apply local changes
                NSString *returnString = [[NSString alloc] initWithData:returndata encoding:NSUTF8StringEncoding];
                NSLog(@"Got Status Code: %d",[((NSHTTPURLResponse *)response) statusCode]);
                if([((NSHTTPURLResponse *)response) statusCode] == 200){
                    // Check to see if we need to download a snapshot
                    NSLog(@"HTTP RESPONSE: %@",returnString);
                    NSArray *returnObject = [NSJSONSerialization JSONObjectWithData:returndata options:kNilOptions error:nil];
                    // Sync transactions
                    [self syncTransactions:returnObject];
                } else {
                    // Try to eport the upstream sync failure
                    NSLog(@"HTTP RESPONSE: %@",returnString);
                    [self reportSyncErrorWithData:result];
                }
                
                // Delete changes
                NSDictionary *condition = [[NSDictionary alloc] initWithObjectsAndKeys:[[result objectForKey:@"RemoteCall"] objectForKey:@"id"], @"id", nil];
                NSDictionary *conditions = [[NSDictionary alloc] initWithObjectsAndKeys:condition, @"conditions", nil];
                [[_modelManager modelWithName:@"RemoteCall"] deleteWithQueryData:conditions];
                // Process Another
                continue;
            }
        }
        @catch (NSException *exception) {
            NSLog(@"Error %@ - %@", [exception name], [exception reason]);
        }
        [NSThread sleepForTimeInterval:10];
    }
}


-(void)reportSyncErrorWithData:(NSDictionary *)data{
    // Prep data for post
    NSMutableDictionary *mdata = [data mutableCopyDeep];
    NSString *postString = [[data objectForKey:@"RemoteCall"] objectForKey:@"post_data"];
    NSDictionary *postData = [NSJSONSerialization JSONObjectWithData:[postString dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
    [mdata setValue:postData forKeyPath:@"RemoteCall.post_data"];
    NSString *fullUrl = [[NSString alloc] initWithFormat:@"%@/api/sync/emailAlert.json", _baseURL];
    NSMutableURLRequest *request = [self getApiRequestWithUrl:fullUrl];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[[NSJSONSerialization stringWithJSONObject:mdata options:kNilOptions error:nil] dataUsingEncoding:NSUTF8StringEncoding]];
    NSError *error;
    NSURLResponse *response;
    NSData *returndata = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    // Tell apply local changes
    NSString *returnString = [[NSString alloc] initWithData:returndata encoding:NSUTF8StringEncoding];
    NSLog(@"Got Status Code: %d",[((NSHTTPURLResponse *)response) statusCode]);
    if([((NSHTTPURLResponse *)response) statusCode] != 200){
        // Try to eport the upstream sync failure
        @throw [NSException exceptionWithName: @"ApiError"
                                       reason: [NSString stringWithFormat:@"An exception occurred while trying to sync data upstream: %@", returnString]
                                     userInfo: nil];
    }
}

# pragma mark Transaction Applications

-(void)syncTransactions:(NSArray *)transactions{
    for(NSDictionary *transaction in transactions){
        if([self syncTransaction:transaction]){
            NSNumber *trans = [transaction objectForKey:@"id"];
            [self setTransactionId:[trans intValue]];
        }
    }
}

/**
 *
 */
-(BOOL)syncTransaction:(NSDictionary *)transaction{
    NSString *modelName = [transaction objectForKey:@"model_name"];
    NSString *action = [transaction objectForKey:@"action"];
    CakeModel *model = [_modelManager modelWithName:modelName];
    if([action isEqualToString:@"D"]){
        // delete the record
        // In this case data should hold the primary keys {ModelName:{PK1:V1, PK2:V2}}
        NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
        [data setObject:[transaction objectForKey:@"primary_key"]
                 forKey:[NSString stringWithFormat:@"%@", [[model primaryKeys] objectAtIndex:0]]];
        NSDictionary *params = [[NSDictionary alloc ] initWithObjectsAndKeys:data, @"conditions", nil];
        if([model deleteWithQueryData:params]){
            return true;
        }
        return false;
    }
    if ([action isEqualToString:@"I"]){
        // We are inserting, so flag the model for an insert
        [model create];
    }
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    [data setObject:[transaction objectForKey:@"data"] forKey:modelName];
    // save the data
    if([model saveWithData:data]){
        return true;
    }
    return false;
}

@end
