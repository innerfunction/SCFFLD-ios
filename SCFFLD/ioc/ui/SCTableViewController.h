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

#import <UIKit/UIKit.h>
#import "SCTableData.h"
#import "SCTableViewCellFactory.h"
#import "SCIOCTypeInspectable.h"
#import "SCIOCConfigurationInitable.h"
#import "SCIOCContainerAware.h"
#import "SCIOCConfigurationAware.h"
#import "SCMessageReceiver.h"
#import "SCActionProxy.h"
#import "SCAppContainer.h"

// Following pragmas are to disable build warning caused by use of UISearchDisplayController;
// these can be removed (and the trailing pragma at end of file) once this class is migrated
// to the replacement UISearchController class.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/**
 * A configurable table view component.
 * The following configuration keys are used to control the table's basic display:
 * - _tableStyle_:      String to control the table style; values are "Grouped" or "Plain". See UITableViewStyle.
 * - _backgroundColor_: The table's background color.
 *
 * Table data can be presented as plain (non-grouped) or grouped. @see <SCTableData>:
 * - Plain tables:   Data should be an NSArray of table cell data.
 * - Grouped tables: Data should be an NSArray of table sections, where each section is an NSArray of table cell data.
 *
 * Each table cell data item must be an NSDictionary with the following properties:
 * - _title_:           The main text displayed on the cell.
 * - _description_:     Additional text displayed below the title (Optional).
 * - _image_:           URI of an image to display on the LHS of the cell (Optional).
 * - _accessory_        Type of the accessory view displayed on the RHS of the cell (Optional).
 *                      Takes the following values, corresponding to the values defined for UITableViewCellAccessoryType:
 *                      - None
 *                      - DisclosureIndicator
 *                      - DetailButton
 *                      - Checkmark
 * - _style_:           The cell style. Overrides the style specified in the configuration when supplied (Optional).
 *                      Has the following values, corresponding to the values defined by UITableViewCellStyle:
 *                      - Default
 *                      - Style1
 *                      - Style2
 *                      - Subtitle
 * - _backgroundImage_: A cell background image. (Optional).
 * - _selectedBackgroundImage_: A cell background image when selected. (Optional).
 * - _height_:          The row height.
 * - _action_:          An action message which is posted when a table cell is selected.
 */
@interface SCTableViewController : UITableViewController <UITableViewDelegate, UISearchDisplayDelegate, UISearchBarDelegate, SCIOCTypeInspectable, SCIOCConfigurationInitable, SCIOCContainerAware, SCIOCConfigurationAware, SCMessageReceiver, SCActionProxy> {
    
    /// The table's search bar.
    UISearchBar *_searchBar;
    UISearchDisplayController *_searchDisplayController;
    /// The default factory for generating table cells.
    SCTableViewCellFactory *_defaultFactory;
    BOOL _isFirstShow;
    /// A dictionary used by the _SCActionProxy_ protocol methods.
    NSMutableDictionary *_actionProxyLookup;
    /// The app container.
    SCAppContainer *_appContainer;
}

/// Flag indicating whether to hide the screen's title bar.
@property (nonatomic, assign) BOOL hideTitleBar;
/// The title of the back button.
@property (nonatomic, strong) NSString *backButtonTitle;
/// An optional left-side title bar item.
@property (nonatomic, strong) UIBarButtonItem *leftTitleBarButton;
/// An optional right-side title bar item.
@property (nonatomic, strong) UIBarButtonItem *rightTitleBarButton;
/**
 * A map of additional cell factories. Different cell factories can be configured via this property, supporting the
 * generation of table cells with different display properties. Which cell factory is used is controlled by a "mode"
 * property in the cell data. If the "mode" value corresponds to the key of one of the factories in this map then
 * that factory is used to generate the cell, otherwise the default cell is used.
 */
@property (nonatomic, strong) NSDictionary *cellFactoriesByDisplayMode;
/// The colour of the section title text.
@property (nonatomic, strong) UIColor *sectionTitleColor;
/// The background colour for section titles.
@property (nonatomic, strong) UIColor *sectionTitleBackgroundColor;
/// Flag indicating whether the table should scroll to the selected cell when displayed.
@property (nonatomic, assign) BOOL scrollToSelected;
/// The table's data.
@property (nonatomic, strong) SCTableData *tableData;
/// The ID of the selected cell. Set to the value of the "id" property of a cell data item.
@property (nonatomic, strong) NSString *selectedID;
/// Flag indicating whether the table has a search bar.
@property (nonatomic, assign) BOOL hasSearchBar;
/// A message which is displayed when the search filter is cleared.
@property (nonatomic, strong) NSString *clearFilterMessage;
/// The table's content.
@property (nonatomic, strong) id content;
/// The table's row data. Use this to configure a rows data.
@property (nonatomic, strong) id<SCConfiguration> rows;
/// The table's row data. Use this when passing row data programmatically.
@property (nonatomic, strong) NSArray *rowsArray;
/// A named filter to apply to the content before displaying.
@property (nonatomic, strong) NSString *filterName;

/**
 * Get the action for the row at the specified index path.
 * Called when a table row is selected. Default implementation reads the "action"
 * property of the row's data item.
 */
- (NSString *)actionForRowAtIndexPath:(NSIndexPath *)indexPath;
/// Format incoming list data. Principally intended as a mechanism for subclasses to interface with specific data sources.
- (NSArray *)formatData:(NSArray *)data;
/// Clear any currently applied table data filter.
- (void)clearFilter;
/// Post a message.
- (void)postMessage:(NSString *)message;
/// Return a table data filter block for the named filter.
- (SCTableDataFilterBlock)filterBlockForName:(NSString *)filterName;

@end

// See note on pragmas at top of file.
#pragma clang diagnostic pop

