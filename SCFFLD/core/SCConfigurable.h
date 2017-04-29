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
//  Created by Julian Goacher on 22/04/2015.
//  Copyright (c) 2015 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCConfiguration.h"

@protocol SCContainer;

/**
 * Protocol for objects which wish to control their own configuration.
 * Objects which implement this protocol are essentially declaring to the IOC container that
 * they will take responsibility for their own configuration. Consequently, the container
 * will not perform dependency injection on any of the object's properties.
 */
@protocol SCConfigurable <NSObject>

/** Configure the object using the specified configuration. */
- (void)configure:(id<SCConfiguration>)configuration inContainer:(id<SCContainer>)container;

@end
