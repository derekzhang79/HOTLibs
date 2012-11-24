//
//  HOTSync.m
//  HOTSync
//
//  Created by Jose Avila III on 10/26/12.
//  Copyright (c) 2012 Jose Avila III. All rights reserved.
//

#import "HOTSync.h"

@implementation HOTSync

-(void)setTransactionId:(int)transactionId{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"HOTSyncTransactionIdDidChangeNotification" object:self];
}

-(id)initWithModelManager:(HOTModelManager *)modelMgr andDataSource:(NSString *)datasource andBaseURL:(NSString *)baseUrl{
    self = [super init];
    if(self){
        _modelManager = modelMgr;

        _baseURL = baseUrl;
        
        _deviceId = [[UIDevice currentDevice] identifier];
        _deviceModel = [[UIDevice currentDevice] model];
        _deviceName = [[UIDevice currentDevice] name];
        _deviceSystemName = [[UIDevice currentDevice] systemName];
        _deviceSystemVersion = [[UIDevice currentDevice] systemVersion];
        
        _apiVersion = @"2.0";
        
        _datasource = datasource;
        
        // Add the local datasource associated with this datasource
        NSString *path = [NSString stringWithFormat:@"%@.local", [[_modelManager getDatabaseWithDatasource:datasource] path]];
        NSDictionary *config = [[NSDictionary alloc] initWithObjectsAndKeys:
                                path, @"Path",
                                nil];
        [_modelManager addDatasourceWithName:@"local" andConfig:config];
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
    
    NSString *fullUrl = [[NSString alloc] initWithFormat:@"%@%@", _baseURL, url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fullUrl]
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:5];
    [request setValue:_deviceId forHTTPHeaderField:@"X-HotSync-DeviceId"];
    [request setValue:_deviceModel forHTTPHeaderField:@"X-HOTSync-DeviceModel"];
    [request setValue:_deviceName forHTTPHeaderField:@"X-HOTSync-DeviceName"];
    [request setValue:_deviceSystemName forHTTPHeaderField:@"X-HOTSync-DeviceSystemName"];
    [request setValue:_deviceSystemVersion forHTTPHeaderField:@"X-HOTSync-DeviceSystemVersion"];
    [request setValue:_apiVersion forHTTPHeaderField:@"X-HOTSync-ApiVersion"];
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
        @try {
            [self syncDownstreamUpToDate];
        }
        @catch (NSException *exception) {
            NSLog(@"Trapped Exception: %@", [exception name]);
        }
        @finally {
            // sleep for a small period to not slam the servers
            [NSThread sleepForTimeInterval:30];
        }
    }
}

/**
 *
 */
-(void)downloadSnapshot:(NSDictionary *)data{
    // Need to alculate the time it takes to download the snapshot here
    HOTDatabase *database = [_modelManager getDatabaseWithDatasource:_datasource];
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
        int appliedTransactions = [self syncDownstream];
        if(appliedTransactions == 0){
            return;
        }
    }
}

/**
 * Attempt to sync datadownstream. Return the number of changes that were applied
 */
-(int)syncDownstream{
    NSURLRequest *request = [self getApiRequestWithUrl:[[NSString alloc] initWithFormat:@"/api/sync/sync/%d.json", _transactionId]];
    NSError *error;
    NSURLResponse *response;
    NSData *returndata = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if(returndata){
        [self setFullSyncDateDownstream:[NSDate date]];
        // if there was not an error getting the data.
        NSString *returnString = [[NSString alloc] initWithData:returndata encoding:NSUTF8StringEncoding];
        if([((NSHTTPURLResponse *)response) statusCode] != 200){
            // This may be telling you to grab a snapshot
            NSDictionary *returnObject = [NSJSONSerialization JSONObjectWithData:[returnString dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
            if(returnObject && [returnObject isKindOfClass:[NSDictionary class]] && [[returnObject objectForKey:@"code"] intValue] == 1){
                // you are being told to grab a snapshot.
                [self downloadSnapshot:[returnObject objectForKey:@"data"]];
                // This should probably return the maxtransaction id
                return 1;
            }  else {
                //NSLog(@"HTTP RESPONSE: %@",returnString);
                @throw [NSException exceptionWithName: @"ApiError"
                                               reason: @"An exception occurred while trying to sync data downstream"
                                             userInfo: nil];
            }
        } else {
            // Parse the return object and apply the changes
            NSArray *returnObject = [NSJSONSerialization JSONObjectWithData:[returnString dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
            // Sync transactions
            if([returnObject count] != 0){
                [self syncTransactions:returnObject];
                // Continue will skip to the loop again without sleeping as there may be more updates
                return [returnObject count];
            }
        }
    }
    // At this point we should be done processing and up to date
    return 0;
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
                NSString *fullUrl = [[NSString alloc] initWithFormat:@"/api/%@.json", [[result objectForKey:@"RemoteCall"] objectForKey:@"method"]];
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
    NSString *fullUrl = @"/api/sync/emailAlert.json";
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
            _transactionId = [trans intValue];
            //[self setTransactionId:[trans intValue]];
        }
    }
}

/**
 *
 */
-(BOOL)syncTransaction:(NSDictionary *)transaction{
    NSString *modelName = [transaction objectForKey:@"model_name"];
    NSString *action = [transaction objectForKey:@"action"];
    HOTModel *model = [_modelManager modelWithName:modelName];
    // If the model is valid try to set the data
    if(model != nil){
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
        } else if ([action isEqualToString:@"I"] || [action isEqualToString:@"U"]){
            
            if ([action isEqualToString:@"I"]){
                // We are inserting, so flag the model for an insert
                [model create];
            }
            NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
            [data setObject:[transaction objectForKey:@"data"] forKey:modelName];
            // save the data
            bool ret = [model saveWithData:data];
            if(ret){
                return true;
            }
        }
    }
    return false;
}

@end
