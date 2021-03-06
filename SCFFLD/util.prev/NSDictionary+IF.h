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
//  Created by Julian Goacher on 21/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (IF)

/**
 * Return a new dictionary composed of the values in the current dictionary, plus the values in the argument.
 * Both the self and argument dictionarys are unchanged.
 */
- (NSDictionary *)extendWith:(NSDictionary *)values;

/**
 * Return a dictionary with the specified key/value pair added.
 * Modifies the self dictionary if possible, otherwise returns a new copy of the self dictionary with the key/pair added.
 */
- (NSDictionary *)dictionaryWithAddedObject:(id)object forKey:(id)key;

/**
 * Return a new dictionary with the specified keys excluded.
 */
- (NSDictionary *)dictionaryWithKeysExcluded:(NSArray *)excludedKeys;

@end
