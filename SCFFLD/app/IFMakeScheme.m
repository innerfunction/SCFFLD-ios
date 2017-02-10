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
//  Created by Julian Goacher on 22/10/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFMakeScheme.h"

@implementation IFMakeScheme

- (id)initWithAppContainer:(IFAppContainer *)container {
    self = [super init];
    if (self) {
        _container = container;
    }
    return self;
}

- (IFCompoundURI *)resolve:(IFCompoundURI *)uri against:(IFCompoundURI *)reference {
    return uri;
}

- (id)dereference:(IFCompoundURI *)uri parameters:(NSDictionary *)params {
    id result = nil;
    IFConfiguration *config = nil;
    if (uri.name) {
        // Build a pattern.
        config = [_container.patterns getValueAsConfiguration:uri.name];
    }
    else {
        // Build a configuration.
        id _config = params[@"config"];
        if ([_config isKindOfClass:[IFConfiguration class]]) {
            config = (IFConfiguration *)_config;
        }
        else if ([_config isKindOfClass:[IFResource class]]) {
            config = [[IFConfiguration alloc] initWithResource:(IFResource *)_config];
        }
    }
    if (config) {
        result = [_container buildObjectWithData:config parameters:params identifier:[uri description]];
    }
    return result;
}

@end
