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
//  Created by Julian Goacher on 23/04/2015.
//  Copyright (c) 2015 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * A protocol which allows an IOC container to interrogate an object about the default
 * type of members of collection properties of the object.
 * This protocol is provided to overcome shortcomings in an IOC container's type inference
 * mechanism when dealing with collection (e.g. NSArray or NSDictionary based) object
 * properties. In such cases, the container has no way to know what type the collection
 * members should be, and so has no way to automatically infer a member type if the member
 * item configuration doesn't container an instantiation hint. However, if the parent
 * object (i.e. the object the collection property belongs to) implements this protocol,
 * then the container can ask the object for a default type for the collection's members.
 */
@protocol SCIOCTypeInspectable <NSObject>

/**
 * Return a dictionary of collection property names onto expected types.
 * The dictionary's keys should be the names of property collections of the current object.
 * Each corresponding value should be a _Class_ or _Protocol_ instance specifying the expected
 * type of members of the named collection. If no member type information is provided for any
 * property then the type mapping defaults to _id_.
 */
- (NSDictionary *)collectionMemberTypeInfo;

@end
