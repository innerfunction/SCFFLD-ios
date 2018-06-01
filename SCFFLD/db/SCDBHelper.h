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

#import <Foundation/Foundation.h>
#import "SCSqlite.h"

/// A protocol used to delegate certain database lifecyle events.
@protocol SCDBHelperDelegate <NSObject>

/// Handle database creation; used to setup the initial database schema.
- (void)onCreate:(SCSqliteDB *)database error:(NSError **)error;
/// Handle a database schema upgrade.
- (void)onUpgrade:(SCSqliteDB *)database from:(NSInteger)oldVersion to:(NSInteger)newVersion error:(NSError **)error;

@optional

/// Handle a database open.
- (void)onOpen:(SCSqliteDB *)database;

@end

@interface SCDBHelper : NSObject {
    /// The database name.
    NSString *_databaseName;
    /// The database schema version.
    int _databaseVersion;
    /// The path to the database file.
    NSString *_databasePath;
    /// Flag indicating whether the perform the initial copy check.
    BOOL _doInitialCopyCheck;
}

/// Delegate for handling database creation / upgrade.
@property (nonatomic, strong) id<SCDBHelperDelegate> delegate;
/**
 * The path to an initial copy of the database. Used to provide an initial version of the database
 * schema and content; if specified, then the file at this location is copied to the database path
 * before a database connection is opened.
 */
@property (nonatomic, strong) NSString *initialCopyPath;

/// Initialize the helper with a database name and version.
- (id)initWithName:(NSString *)name version:(int)version;
/// Delete the database.
- (BOOL)deleteDatabase;
/// Get a connection to the database.
- (SCSqliteDB *)getDatabase;
/// Close the database.
- (void)close;

@end
