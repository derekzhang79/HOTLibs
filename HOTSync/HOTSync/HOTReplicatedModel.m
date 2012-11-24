//
//  HOTReplicatedModel.m
//  HOTSync
//
//  Created by Jose Avila III on 10/27/12.
//  Copyright (c) 2012 Jose Avila III. All rights reserved.
//
//  When using the HOTSync, you should subclass all your models from HOTReplicatedModel.
//  Your client should only call saveLocalWithData as it will not modify the "Always good"
//  database.

#import "HOTReplicatedModel.h"

@implementation HOTReplicatedModel


# pragma mark Data find methods


/*
 * Return an array of local changes
 */
-(NSArray *)findLocalChanges{
    NSDictionary *lparams = [[NSDictionary alloc] initWithObjectsAndKeys:
                             [[NSDictionary alloc] initWithObjectsAndKeys:
                              _name, @"Change.model_name",
                              nil], @"conditions",
                             [[NSArray alloc] initWithObjects:
                              @"Change.action",
                              @"Change.data",
                              @"Change.primary_key1",
                              nil], @"fields",
                             nil];
    NSArray *localChanges = [[_modelManager modelWithName:@"Change"] findWithType:@"all" andQuery:lparams];
    return localChanges;
}

/*
 * Apply the local changes to the result set
 */
-(NSMutableArray *)applyLocalChangesToResultSet:(NSMutableArray *)results{
    NSArray *localChanges = [self findLocalChanges];
    for(NSMutableDictionary* result in results){
        BOOL modifiedRecord = false;
        for(NSMutableDictionary *localChange in localChanges){
            // check to see if the change applies to the result
            if([[localChange valueForKeyPath:@"Change.action"] isEqualToString:@"u"]){
                //NSString *key = [NSString stringWithFormat:@"%@.%@", _name, [_primaryKeys objectAtIndex:0]];
                // TODO: Support multiple key primary keys
                
                if([[localChange valueForKeyPath:@"Change.primary_key1"] isEqualToString:[[result valueForKeyPath:[_primaryKeys objectAtIndex:0]] stringValue]]){
                    // The primary keys lined up so this update applies to the object
                    
                    NSDictionary *changeData = (NSDictionary *)[NSJSONSerialization objectWithJSONString:[localChange valueForKeyPath:@"Change.data"]];
                    for(NSString *key in [[changeData objectForKey:_name] allKeys]){
                        // Update the appropriate value
                        NSString *keyPath = [NSString stringWithFormat:@"%@.%@", _name, key];
                        // TODO: We probably want to compare instead of just overriding the value
                        [result setValue:[changeData valueForKeyPath:keyPath] forKeyPath:key];
                        modifiedRecord = true;
                    }
                }
            }
            if([[localChange valueForKeyPath:@"Change.action"] isEqualToString:@"d"]){
                [results removeObject:result];
                break;
            }
        }
        // TODO: Check to see if the modified record still matches the query conditions
        // if(modifiedRecord && ![result matchesQuery])
        //     [results removeObject:result];
    }
    for(NSMutableDictionary *localChange in localChanges){
        if([[localChange valueForKeyPath:@"Change.action"] isEqualToString:@"i"]){
            // TODO:  Check to see if the modified record  matches the query conditions
            // if([localChange matchesQuery])
            //     [results addObject:result];
        }
        
    }
    
    return results;
}

-(NSArray *)dataSourceReadWithQueryData:(NSDictionary *)queryData{
    NSArray *results = [super dataSourceReadWithQueryData:queryData];
    return [self applyLocalChangesToResultSet:[results mutableCopy]];
}

# pragma mark Data manipulation methods
/**
 * This method is used to save data locally to the remote calls / changes table
 */
-(BOOL)saveLocalWithData:(NSDictionary *)data{
    //
    //NSMutableDictionary *mutableChangeData = [data mutableCopyDeep];
    for(NSString *key in _primaryKeys){
        if([[data objectForKey:_name] objectForKey:key] == nil){
            return NO;
        }
    }
    NSString *method;
    if(_inserting){
        method = [NSString stringWithFormat:@"%@/add", _table];
    } else {
        method = [NSString stringWithFormat:@"%@/edit", _table];
    }
    // Log the remote call
    NSDictionary *mdata = [[NSDictionary alloc]initWithObjectsAndKeys:
                           method, @"method",
                           [NSJSONSerialization stringWithJSONObject:data options:kNilOptions error:nil], @"post_data",
                           nil];
    
    NSDictionary *rdata = [[NSDictionary alloc] initWithObjectsAndKeys:mdata, @"RemoteCall", nil];
    [[_modelManager modelWithName:@"RemoteCall"] create];
    [[_modelManager modelWithName:@"RemoteCall"] saveWithData:rdata];
    // Get the remote Call id
    NSNumber *remoteId = [[_modelManager modelWithName:@"RemoteCall"] insertedId];
    
    // Log the percieved changes
    return [self saveChangesWithData:data andRemoteCallId:remoteId];
}

/**
 * Save the changes wo we can combine the results on the find.
 */
-(BOOL)saveChangesWithData:(NSDictionary *)data andRemoteCallId:(NSNumber *)remoteCallId{
    NSMutableDictionary *c = [[NSMutableDictionary alloc] init];
    [c setValue:[remoteCallId stringValue] forKey:@"remote_call_id"];
    [c setValue:_name forKey:@"model_name"];
    // TODO Actually write the save method
    //Change *changeModel = [[Change alloc] initWithClient:client];
    // Detect if insert or update
    if(_inserting){
        // This is an insert
        [c setValue:@"i" forKey:@"action"];
    } else {
        // This is an update
        int pkidx=1;
        for(NSString *key in _primaryKeys){
            if([[data objectForKey:_name] objectForKey:key] == nil){
                return NO;
            }
            [c setValue:[[data objectForKey:_name] objectForKey:key] forKey:[NSString stringWithFormat:@"primary_key%d", pkidx]];
            pkidx += 1;
        }
        [c setValue:@"u" forKey:@"action"];
    }
    [c setValue:[NSJSONSerialization stringWithJSONObject:data options:kNilOptions error:nil] forKey:@"data"];
    NSMutableDictionary *cdata = [[NSMutableDictionary alloc] init];
    [cdata setValue:c forKey:@"Change"];
    [[_modelManager modelWithName:@"Change"] create];
    return [[_modelManager modelWithName:@"Change"] saveWithData:cdata];
}

/**
 * This method is used to save data locally to the remote calls / changes table
 */

-(BOOL)deleteLocalWithQueryData:(NSDictionary *)queryData{
    // TODO: (Medium) Support deleting of records
    return YES;
}

-(HOTModel *)HOTModel{
    HOTModel *model = [[HOTModel alloc] initWithModelManager:_modelManager];
    [model setName:_name];
    [model setAlias:_alias];
    [model setPrimaryKeys:_primaryKeys];
    [model setUseDbConfig:_useDbConfig];
    [model setTable:_table];
    return model;
}

@end
