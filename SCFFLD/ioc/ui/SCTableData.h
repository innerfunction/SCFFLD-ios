// Copyright 2016 InnerFunction Ltd.
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
//  Created by Julian Goacher on 24/10/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCURIHandling.h"
#import "SCConfiguration.h"

@class SCTableData;

/// A delegate protocol which allows control of the data returned by a table data instance.
@protocol SCTableDataDelegate

/**
 * Get the title for a table section.
 * @param section   The table section data.
 * @param tableData The table data instance.
 */
- (id)getTableDataSectionTitle:(NSDictionary *)section tableData:(SCTableData *)tableData;
/**
 * Get a specific cell data item.
 * @param path      The key path of the data item.
 * @param cellData  Table cell data.
 * @param tableData The table data instance.
 */
- (id)getTableDataForPath:(NSString *)path cellData:(NSDictionary *)cellData tableData:(SCTableData *)tableData;

@end

/// A block type for filtering table data.
typedef BOOL (^SCTableDataFilterBlock) (NSDictionary *row);

/**
 * A class for using JSON array data as a table data source.
 * Uses _NSIndexPath_ to reference cell (row) data, and allows key paths for referencing data items within cell
 * data.
 * Supports both grouped (for tables with sections) and non-grouped data.
 */
@interface SCTableData : NSObject {
    /// An array of the currently visible data items (i.e. after a filter has been applied).
    NSArray *_visibleData;
    /// An array of section header titles.
    NSArray *_sectionHeaderTitles;
    /// A flag indicating whether the data is grouped.
    BOOL _isGrouped;
    /**
     *  A configuration object used to return row data.
     * This is used to allow any URI references within data to resolve correctly.
     */
    id<SCConfiguration> _currentRowData;
    /// A cache of table cell images.
    NSCache *_imageCache;
}

/// Configure the table data using a configuration object.
@property (nonatomic, strong) id<SCConfiguration> rowsConfiguration;
/**
 * Configure the table data. Can be either an array of cell data dictionaries; or an array of section dictionaries.
 * A section dictionary should have the following properties:
 * - _sectionTitle_: The section title.
 * - _sectionData_: An array of cell data items for the section.
 */
@property (nonatomic, strong) NSArray *rowsData;
/**
 * An array of searchable field names.
 * If a filter is applied then the search term is applied to each named field on each cell data item.
 * Defaults to [ "title", "description" ].
 */
@property (nonatomic, strong) NSArray *searchFieldNames;
/// A delegate for modifying how data is resolved.
@property (nonatomic, strong) id<SCTableDataDelegate> delegate;
/// The URI handler to use to resolve table data.
@property (nonatomic, strong) id<SCURIHandler> uriHandler;

/**
 * Get row data for the specified path.
 * This is returned as a configuration object, so that type conversions and URI resolving methods
 * are available.
 */
- (id<SCConfiguration>)rowDataForIndexPath:(NSIndexPath *)path;
/// Test whether the data is empty - i.e. contains no rows.
- (BOOL)isEmpty;
/// Test whether the data is grouped.
- (BOOL)isGrouped;
/// Return the number of sections in the table data.
- (NSInteger)sectionCount;
/// Return the number of rows in the specified section.
- (NSInteger)sectionSize:(NSInteger)section;
/// Return the title for the specified section.
- (NSString *)sectionTitle:(NSInteger)section;
/**
 * Filter the table data by applying a search term.
 * @param searchTerm    The string to search for.
 * @param scope         An optional field name to limit the search to. If not specified then uses
 * the fields defined in _searchFieldNames_.
 */
- (void)filterBy:(NSString *)searchTerm scope:(NSString *)scope;
/**
 * Filter the table data using the specified block.
 * The block is called for each row in the table data with the cell data as its argument. The block
 * should return _true_ if cell data matches the filter test, i.e. should be displayed in the result.
 */
- (void)filterWithBlock:(SCTableDataFilterBlock)filterTest;
/// Clear any filter currently applied to the table data.
- (void)clearFilter;
/// Return the index path of the first row with the specified field name set to the specified value.
- (NSIndexPath *)pathForRowWithValue:(NSString *)value forField:(NSString *)name;
/// Load an image from row data.
- (UIImage *)loadImageWithRowData:(id<SCConfiguration>)rowData dataName:(NSString *)dataName defaultImage:(UIImage *)defaultImage;
/// Load an image from row data.
- (UIImage *)loadImageWithRowData:(id<SCConfiguration>)rowData dataName:(NSString *)dataName width:(CGFloat)width height:(CGFloat)height defaultImage:(UIImage *)defaultImage;
/*
/// Resolve an image from an image reference.
- (UIImage *)dereferenceImage:(NSString *)imageRef;
*/

@end
