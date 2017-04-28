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
//  Created by Julian Goacher on 07/03/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import "SCConfiguration.h"
#import "SCResource.h"
#import "SCValues.h"

/**
 * A class used to parse and access component configurations.
 */
@interface SCIOCConfiguration : NSObject <SCConfiguration>

/// Initialize a configuration with the specified data.
- (id)initWithData:(id)data;
/// Initialize a configuration with data read from the specified resource.
- (id)initWithResource:(SCResource *)resource;
/// Initialize a configuration with the specified data and parent configuration.
- (id)initWithData:(id)data parent:(id<SCConfiguration>)parent;

/// Returns a singleton-instance empty configuration object.
+ (id<SCConfiguration>)emptyConfiguration;

@end
