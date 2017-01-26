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

#import <Foundation/Foundation.h>
#import "IFURIHandling.h"
#import "IFAppContainer.h"

/**
 * An internal URI handler for the _make:_ scheme.
 * The _make:_ scheme allows objects to be instantiated from pre-defined configuration
 * patterns, or directly from configuration files.
 * When used to instantiate a pattern, the name of the pattern must be specified in the _name_
 * part of the URI. The URI's parameters are then passed to the pattern as configuration
 * parameters.
 * When used to instantiate an object from a configuration file, the _name_ part of the URI
 * is left empty, and a single _config_ parameter must be given, resolving to the configuration
 * to be instantiated.
 */
@interface IFMakeScheme : NSObject <IFSchemeHandler> {
    IFAppContainer *_container;
}

- (id)initWithAppContainer:(IFAppContainer *)container;


@end
