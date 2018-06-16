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
//  Created by Julian Goacher on 25/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef id (^SCArrayMapBlock) (id, NSUInteger);
typedef id (^SCArrayReduceBlock) (id, id, NSUInteger);

@interface NSArray (SC)

+ (NSArray *)arrayWithDictionaryKeys:(NSDictionary *)dictionary;

+ (NSArray *)arrayWithDictionaryValues:(NSDictionary *)dictionary forKeys:(NSArray *)keys;

+ (NSArray *)arrayWithItem:(id)item repeated:(NSInteger)repeats;

- (NSArray *)arrayWithoutItem:(id)item;

- (NSArray *)arrayWithoutHeadItem;

- (NSArray *)arrayMapWithBlock:(SCArrayMapBlock)block;

- (id)arrayReduceWithBlock:(SCArrayReduceBlock)block accumulator:(id)acc;

@end
