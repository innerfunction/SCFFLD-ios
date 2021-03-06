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
//  Created by Julian Goacher on 23/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "SCI18nMap.h"

@implementation SCI18nMap

- (id)valueForKey:(NSString *)key {
    NSString *s = NSLocalizedString(key, @"");
    return s ? s : key;
}

static SCI18nMap *instance;

+ (void)initialize {
    instance = [[SCI18nMap alloc] init];
}

+ (SCI18nMap *)instance {
    return instance;
}

@end
