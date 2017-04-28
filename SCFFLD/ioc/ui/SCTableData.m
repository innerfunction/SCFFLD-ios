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

#import "SCTableData.h"
#import "SCTypeConversions.h"
#import "SCIOCConfiguration.h"
#import "UIImage+CropScale.h"
#import "objc/runtime.h"

@interface SCTableData ()

- (void)_setRowsData:(NSArray *)data;

@end

@implementation SCTableData

- (id)init {
    self = [super init];
    if (self) {
        // Initialize the object with an empty data array.
        self.rowsData = @[];
        self.searchFieldNames = @[ @"title", @"description" ];
    }
    return self;
}

- (void)setRowsConfiguration:(id<SCConfiguration>)rowsConfiguration {
    _rowsConfiguration = rowsConfiguration;
    _currentRowData = [[SCIOCConfiguration alloc] initWithData:@{} parent:_rowsConfiguration];
    NSArray *rowsData;
    id sourceData = rowsConfiguration.sourceData;
    if ([sourceData isKindOfClass:[NSArray class]]) {
        rowsData = (NSArray *)sourceData;
    }
    else {
        rowsData = @[];
    }
    [self _setRowsData:rowsData];
}

- (void)setRowsData:(NSArray *)rowData {
    _rowsConfiguration = [SCIOCConfiguration emptyConfiguration];
    _currentRowData = [[SCIOCConfiguration alloc] initWithData:@{} parent:_rowsConfiguration];
    [self _setRowsData:rowData];
}

// Set the table data.
- (void)_setRowsData:(NSArray *)data {
    // Test whether the data is grouped or non-grouped. If grouped, then extract section header titles from the data.
    // This method allows grouped data to be presented in one of two ways, and assumes that the data is grouped
    // consistently throughout.
    // * The first grouping format is as an array of arrays. The section header title is extracted as the first character
    // of the title of the first item in each group.
    // * The second grouping format is as an array of dictionaries. Each dictionary represents a section object with
    // 'title' and 'rows' properties.
    // Data can also be presented as an array of strings, in which case each string is used as a row title.
    id firstItem = [data count] > 0 ? data[0] : nil;
    if ([firstItem isKindOfClass:[NSArray class]]) {
        _isGrouped = YES;
        NSMutableArray *titles = [[NSMutableArray alloc] initWithCapacity:[data count]];
        for (NSArray *section in data) {
            NSDictionary *row = section[0];
            if (row) {
                [titles addObject:[(NSString*)row[@"title"] substringToIndex:1]];
            }
            else {
                [titles addObject:@""];
            }
        }
        _rowsData = data;
        _sectionHeaderTitles = titles;
    }
    else if ([firstItem isKindOfClass:[NSDictionary class]]) {
        // A 'rows' property on the row indicates a table section.
        if (firstItem[@"rows"]) {
            _isGrouped = YES;
            NSMutableArray *titles = [[NSMutableArray alloc] initWithCapacity:[data count]];
            NSMutableArray *sections = [[NSMutableArray alloc] initWithCapacity:[data count]];
            for (NSDictionary *section in data) {
                NSString *sectionTitle = [_delegate getTableDataSectionTitle:section tableData:self];
                if (sectionTitle == nil) {
                    sectionTitle = section[@"title"];
                }
                [titles addObject:(sectionTitle ? sectionTitle : @"")];
                NSArray *sectionRows = section[@"rows"];
                [sections addObject:(sectionRows ? sectionRows : @[])];
            }
            _rowsData = sections;
            _sectionHeaderTitles = titles;
        }
        else {
            _isGrouped = NO;
            _rowsData = data;
        }
    }
    else if ([firstItem isKindOfClass:[NSString class]]) {
        _isGrouped = NO;
        NSMutableArray *rows = [[NSMutableArray alloc] initWithCapacity:[data count]];
        for (NSString *title in data) {
            [rows addObject:@{ @"title": title }];
        }
        _rowsData = rows;
    }
    else {
        _isGrouped = NO;
        _rowsData = @[];
    }
    _visibleData = _rowsData;
}

// Get cell data for the specified path.
- (id<SCConfiguration>)rowDataForIndexPath:(NSIndexPath *)path {
    // Resolve the cell data. First check the type of the first data item.
    // - If data is empty then result will be nil.
    // - If first data item is an NSArray then we're dealing with a grouped list (i.e. with sections).
    // - Else we are dealing with non-grouped data.
    NSDictionary *cellData = nil;
    if ([_visibleData count] > 0) {
        if (_isGrouped) {
            if ([_visibleData count] > path.section) {
                NSArray *sectionData = _visibleData[path.section];
                if ([sectionData count] > path.row) {
                    cellData = sectionData[path.row];
                }
            }
        }
        else if ([_visibleData count] > path.row) {
            cellData = _visibleData[path.row];
        }
    }
    // Reuse the current row data config object.
    _currentRowData.configData = cellData;
    return _currentRowData;
}

- (BOOL)isEmpty {
    // TODO: A more complete implementation would take accout of grouped data with multiple empty sections.
    return [_rowsData count] == 0;
}

- (BOOL)isGrouped {
    return _isGrouped;
}

// Return the number of sections in the table data.
- (NSInteger)sectionCount {
    if ([_visibleData count] > 0) {
        return _isGrouped ? [_visibleData count] : 1;
    }
    return 0;
}

- (NSString *)sectionTitle:(NSInteger)section {
    return _sectionHeaderTitles[section];
}

// Return the number of rows in the specified section.
- (NSInteger)sectionSize:(NSInteger)section {
    NSInteger size = 0;
    if ([_visibleData count] > 0) {
        if (_isGrouped) {
            // If first item is an array then we have grouped data, return the size of the section
            // array if it exists, else 0.
            if ([_visibleData count] > section) {
                NSArray *sectionArray = [_visibleData objectAtIndex:section];
                size = [sectionArray count];
            }
            else {
                size = 0;
            }
        }
        else if (section == 0) {
            // We don't have grouped data, but if the required section is 0 then this corresponds to the
            // data array in a non-grouped data set.
            size = [_visibleData count];
        }
    }
    return size;
}

- (void)filterBy:(NSString *)searchTerm scope:(NSString *)scope {
    NSArray *searchNames = scope ? [NSArray arrayWithObject:scope] : self.searchFieldNames;
    SCTableDataFilterBlock filterTest = ^(NSDictionary *row) {
        for (NSString *name in searchNames) {
            NSString *value = row[name];
            if (value && [value rangeOfString:searchTerm options:NSCaseInsensitiveSearch].location != NSNotFound) {
                return YES;
            }
        }
        return NO;
    };
    [self filterWithBlock:filterTest];
}

- (void)filterWithBlock:(SCTableDataFilterBlock)filterTest {
    NSMutableArray *result = [NSMutableArray new];
    if (_isGrouped) {
        for (NSArray *section in _rowsData) {
            NSMutableArray *filteredSection = [NSMutableArray new];
            for (NSDictionary *row in section) {
                if (filterTest(row)) {
                    [filteredSection addObject:row];
                }
            }
            [result addObject:filteredSection];
        }
    }
    else {
        for (NSDictionary *row in _rowsData) {
            if (filterTest(row)) {
                [result addObject:row];
            }
        }
    }
    _visibleData = result;
}

- (void)clearFilter {
    _visibleData = _rowsData;
}

- (NSIndexPath *)pathForRowWithValue:(NSString *)value forField:(NSString *)name {
    if (_isGrouped) {
        for (NSUInteger s = 0; s < [_rowsData count]; s++) {
            NSArray *section = [_rowsData objectAtIndex:s];
            for (NSUInteger r = 0; r < [section count]; r++) {
                NSDictionary *row = section[r];
                if ([value isEqualToString:[row[name] description]]) {
                    return [NSIndexPath indexPathForRow:r inSection:s];
                }
            }
        }
    }
    else {
        for (NSUInteger r = 0; r < [_rowsData count]; r++) {
            NSDictionary *row = _rowsData[r];
            // NOTE: Compare using the string value of the target field so that
            // numeric values specified as a string will match.
            if ([value isEqualToString:[row[name] description]]) {
                return [NSIndexPath indexPathForRow:r inSection:0];
            }
        }
    }
    return nil;
}

#pragma mark - Image handling methods

- (UIImage *)loadImageWithRowData:(id<SCConfiguration>)rowData dataName:(NSString *)dataName defaultImage:(UIImage *)defaultImage {
    UIImage *image = defaultImage;
    // Get the raw image reference to use as an image name.
    NSString *imageName = [rowData.configData valueForKeyPath:dataName];
    if (imageName) {
        image = [_imageCache objectForKey:imageName];
        if (!image) {
            image = [rowData getValueAsImage:dataName];
            if (image) {
                [_imageCache setObject:image forKey:imageName];
            }
            else {
                [_imageCache setObject:[NSNull null] forKey:imageName];
            }
        }
        else if ([[NSNull null] isEqual:image]) {
            // NSNull in the image cache indicates image not found, so return nil.
            image = nil;
        }
    }
    return image;
}

- (UIImage *)loadImageWithRowData:(id<SCConfiguration>)rowData dataName:(NSString *)dataName width:(CGFloat)width height:(CGFloat)height defaultImage:(UIImage *)defaultImage {
    UIImage *image = defaultImage;
    // Get the raw image reference to use as an image name.
    NSString *imageName = [rowData.configData valueForKeyPath:dataName];
    if (imageName) {
        NSString *cacheName = [NSString stringWithFormat:@"%@-%fx%f", imageName, width, height];
        image = [_imageCache objectForKey:cacheName];
        if (!image) {
            image = [rowData getValueAsImage:dataName];
            // Scale the image if we have an image and width * height is not zero (implying that neither value is zero).
            if (image && (width * height)) {
                image = [[image scaleToWidth:width] cropToHeight:height];
                [_imageCache setObject:image forKey:cacheName];
            }
            else {
                [_imageCache setObject:[NSNull null] forKey:_imageCache];
            }
        }
        else if ([[NSNull null] isEqual:image]) {
            // NSNull in the image cache indicates image not found, so return nil.
            image = nil;
        }
    }
    return image;
}

/*
- (UIImage *)dereferenceImage:(NSString *)imageRef {
    UIImage *image = nil;
    if ([imageRef hasPrefix:@"@"]) {
        NSString* uri = [imageRef substringFromIndex:1];
        SCResource *imageRsc = [_tableData.uriHandler dereference:uri];
        if (imageRsc) {
            image = [imageRsc asImage];
        }
    }
    else {
        image = [SCTypeConversions asImage:imageRef];
    }
    return image;
}
*/

@end
