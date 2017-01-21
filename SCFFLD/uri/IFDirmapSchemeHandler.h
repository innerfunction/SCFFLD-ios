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
//  Created by Julian Goacher on 19/01/2017.
//  Copyright © 2017 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFFileBasedSchemeHandler.h"
#import "IFFileResource.h"

@interface IFDirmap : NSDictionary {
    IFDirectoryResource *_dirResource;
    NSArray *_keys;
}

- (id)initWithDirectoryResource:(IFDirectoryResource *)dirResource;

@end

/**
 * The handler for the dirmap: URI scheme.
 * The scheme exists primarily as a way to map JSON files in a directory into
 * a configuration structure.
 */
@interface IFDirmapSchemeHandler : IFFileBasedSchemeHandler {
    NSCache *_dirmapCache;
}

@end
