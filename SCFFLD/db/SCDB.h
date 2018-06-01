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
#import "SCDBHelper.h"
#import "SCDBORM.h"
#import "SCService.h"

/**
 * A SQL database wrapper.
 * Provides methods for performing DB operations - queries, inserts, updates & deletes.
 */
@interface SCDB : NSObject <SCDBHelperDelegate, SCService> {
    SCDBHelper *_dbHelper;
    NSDictionary *_taggedTableColumns;
    NSDictionary *_tableColumnNames;
    NSMutableDictionary *_initialData;
}

/** The database name. */
@property (nonatomic, strong) NSString *name;
/** The current database schema version number. */
@property (nonatomic, strong) NSNumber *version;
/** Flag indicating whether to reset the database at startup. */
@property (nonatomic, assign) BOOL resetDatabase;
/** Database table schemas + initial data. */
@property (nonatomic, strong) NSDictionary *tables;
/** Object/relational mappings defined for the database. */
@property (nonatomic, strong) SCDBORM *orm;
/**
 * The path to an initial copy of the database. If specified, then this will be copied before the
 * database is first used.
 */
@property (nonatomic, strong) NSString *initialCopyPath;

/** Instantiate a new copy of an existing database. */
- (id)initWithDB:(SCDB *)db;
/** Begin a DB transaction. */
- (BOOL)beginTransaction;
/** Commit a DB transaction. */
- (BOOL)commitTransaction;
/** Rollback a DB transaction. */
- (BOOL)rollbackTransaction;
/** Close the thread's current DB connection. */
- (void)closeConnection;
/** Get the name of the column with the specified tag from the named table. */
- (NSString *)getColumnWithTag:(NSString *)tag fromTable:(NSString *)table;
/** Get the record with the specified ID from the named table. */
- (NSDictionary *)readRecordWithID:(NSString *)identifier fromTable:(NSString *)table;
/** Perform a SQL query with the specified parameters. Returns the query result. */
- (NSArray *)performQuery:(NSString *)sql withParams:(NSArray *)params;
/** Perform an update on the database using the specified parameters. Returns YES if the update succeeded. */
- (BOOL)performUpdate:(NSString *)sql withParams:(NSArray *)params;
/** Return the number of records matching the specified where clause in the specified table. */
- (NSInteger)countInTable:(NSString *)table where:(NSString *)where;
/** Return the number of records matching the specified where clause in the specified table. */
- (NSInteger)countInTable:(NSString *)table where:(NSString *)where withParams:(NSArray *)params;
/** Insert a list of values into the named table. Each item of the list is inserted as a new record. Returns true if all records are inserted. */
- (BOOL)insertValueList:(NSArray *)valueList intoTable:(NSString *)table;
/** Insert values into the named table. Returns true if the record is inserted. */
- (BOOL)insertValues:(NSDictionary *)values intoTable:(NSString *)table;
/** Insert values into the named table. Returns true if the record is inserted. */
- (BOOL)insertValues:(NSDictionary *)values intoTable:(NSString *)table db:(SCSqliteDB *)db;
/** Insert or update a list of values into the named table. Each item of the list is inserted as a new record. Returns true if all records are inserted. */
- (BOOL)upsertValueList:(NSArray *)valueList intoTable:(NSString *)table;
/** Insert or update values into the named table. Returns true if the record is inserted. */
- (BOOL)upsertValues:(NSDictionary *)values intoTable:(NSString *)table;
/** Insert or update values into the named table. Returns true if the record is inserted. */
- (BOOL)upsertValues:(NSDictionary *)values intoTable:(NSString *)table db:(SCSqliteDB *)db;
/** Update values in the table. Values must include a value for the ID column for the named table. Returns true if the record updated. */
- (BOOL)updateValues:(NSDictionary *)values inTable:(NSString *)table;
/** Merge a list of values into the named table. Records are inserted or updated as necessary. Returns true if all records were updated/inserted. */
- (BOOL)mergeValueList:(NSArray *)valueList intoTable:(NSString *)table;
/** Delete the identified records from the named table. */
- (BOOL)deleteIDs:(NSArray *)identifiers fromTable:(NSString *)table;
/** Delete the record with the specified ID from the named table. */
- (BOOL)deleteID:(NSString *)recordID fromTable:(NSString *)table;
/**
 * Delete all records matching the specified where clause from the specified table.
 * Note: This is intended for use by the DB manifest processor as part of its garbage collection functionality,
 * so observers aren't notified after this operation - they will be notified after the following update.
 */
- (BOOL)deleteFromTable:(NSString *)table where:(NSString *)where;
/** Filter a set of named/value pairs to only contains names corresponding to a column name in the target db table. */
- (NSDictionary *)filterValues:(NSDictionary *)values forTable:(NSString *)table;
/** Create and return a new instance of this database connection. */
- (SCDB *)newInstance;

@end
