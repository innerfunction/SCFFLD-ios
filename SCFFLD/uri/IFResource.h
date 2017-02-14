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
// limitations under the License
//
//  Created by Julian Goacher on 17/03/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "IFCompoundURI.h"
#import "IFURIHandling.h"

/**
 * An object that can be used to represent the value returned by an internal URI.
 * Allows access to different representations of the same underlying value.
 */
@interface IFResource : NSObject <IFURIContextAware> {
}

/// The resource data i.e. the value referenced by the resource's URI.
@property (nonatomic, strong) id data;

/// Initialize a resource with the specified data and URI.
- (id)initWithData:(id)data uri:(IFCompoundURI *)uri;
/// Access the resource's boolean representation.
- (BOOL)asBoolean;
/// Access the resource's default representation.
- (id)asDefault;
/**
 * Return the resource as an image.
 * @see <IFTypeConversions>.
 */
- (UIImage *)asImage;
/**
 * Access the resource's JSON representation.
 * @see <IFTypeConversions>.
 */
- (id)asJSONData;
/// Access the resource's number representation.
- (NSNumber *)asNumber;
/// Access the resource's string representation.
- (NSString *)asString;
/// Access the resource's URL representation.
- (NSURL *)asURL;
/// Return the resource as an NSData object.
- (NSData *)asData;
/**
 * Return the named resource representation.
 * @see <IFTypeConversions> for a list of supported representation names.
 */
- (id)asRepresentation:(NSString *)representation;
/**
 * Return an external URL for the resource.
 * @return Returns _nil_ for the standard resource type.
 */
- (NSURL *)externalURL;
/**
 * Refresh the resource by resolving its URI again and returning the result.
 */
- (IFResource *)refresh;

@end