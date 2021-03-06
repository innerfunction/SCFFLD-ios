// Copyright 2017 InnerFunction Ltd.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  Created by Julian Goacher on 07/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "SCDBHelper.h"
#import "SCLogger.h"

#define ThreadLocalDB   (@"SCDBHelper.database")

static SCLogger *Logger;

@implementation SCDBHelper

+ (void)initialize {
    Logger = [[SCLogger alloc] initWithTag:@"SCDBHelper"];
}

- (id)initWithName:(NSString *)name version:(int)version {
    self = [super init];
    if (self) {
        _databaseName = name;
        _databaseVersion = version;
        // See http://stackoverflow.com/questions/11252173/ios-open-sqlite-database
        // Need to review whether this is the best/correct location for the db.
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        _databasePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", _databaseName]];
        
        _doInitialCopyCheck = YES;
    }
    return self;
}

- (BOOL)deleteDatabase {
    BOOL ok = YES;
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:_databasePath]) {
        [fileManager removeItemAtPath:_databasePath error:&error];
        if (error) {
            [Logger warn:@"Error deleting database at %@: %@", _databasePath, error];
            ok = NO;
        }
    }
    return ok;
}

- (SCSqliteDB *)getDatabase {
    NSMutableDictionary *threadLocals = [[NSThread currentThread] threadDictionary];
    SCSqliteDB *database = threadLocals[ThreadLocalDB];
    // Connect to database.
    if (!(database != nil && database.open)) {

        NSError *error = nil;

        // Check whether to copy the initial DB copy.
        if (_doInitialCopyCheck) {
            // First check whether to deploy the initial database copy.
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if (![fileManager fileExistsAtPath:_databasePath] && _initialCopyPath) {
                [Logger debug:@"Copying initial database from %@", _initialCopyPath];
                [fileManager copyItemAtPath:_initialCopyPath toPath:_databasePath error:&error];
                if (error) {
                    [Logger warn:@"Error copying initial database: %@", error];
                }
            }
            _doInitialCopyCheck = NO;
        }
        
        // Open a connection to the DB.
        database = [[SCSqliteDB alloc] initWithDBPath:_databasePath error:&error];
        if (error) {
            [Logger error:@"Database open failure: %@", [error localizedDescription]];
        }
        else if (database.open) {
            // Read the database's current version.
            SCSqliteResultSet *rs = [database executeQuery:@"PRAGMA user_version" error:&error];
            if (error) {
                [Logger error:@"Error reading database version: %@", [error localizedDescription]];
            }
            else if ([rs next]) {
                NSInteger currentVersion = [rs columnValueAsInteger:0];
                [rs close];
                // Begin migration, if needed.
                if (currentVersion != _databaseVersion) {
                    // Open a new transaction for the migration.
                    [database executeUpdate:@"BEGIN EXCLUSIVE TRANSACTION" error:&error];
                    if (!error) {
                        // Perform the migration.
                        if (currentVersion == 0) {
                            [_delegate onCreate:database error:&error];
                        }
                        else if (currentVersion < _databaseVersion) {
                            [_delegate onUpgrade:database from:currentVersion to:_databaseVersion error:&error];
                        }
                    }
                    if (!error) {
                        // Update the database version.
                        NSString *sql = [NSString stringWithFormat:@"PRAGMA user_version = %d", _databaseVersion];
                        [database executeUpdate:sql error:&error];
                    }
                    if (!error) {
                        // Commit the migration.
                        [database commitTransaction:&error];
                    }
                    else {
                        [Logger error:@"Error migrating database: %@", [error localizedDescription]];
                    }
                }
            }
            else {
                [Logger error:@"Unable to read database version"];
            }
        }
        threadLocals[ThreadLocalDB] = database;
    }
    return database.open ? database : nil;
}

- (void)close {
    NSMutableDictionary *threadLocals = [[NSThread currentThread] threadDictionary];
    SCSqliteDB *database = threadLocals[ThreadLocalDB];
    if (database) {
        [database close];
        [threadLocals removeObjectForKey:ThreadLocalDB];
    }
}

@end
