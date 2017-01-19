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

#import "IFDirmapSchemeHandler.h"

@implementation IFDirmap

- (id)initWithDirectoryResource:(IFDirectoryResource *)dirResource {
    self = [super init];
    if (self) {
        _dirResource = dirResource;
    }
    return self;
}

- (id)valueForKey:(NSString *)key {
    // Given any key, attempt to load the contents of a file named <key>.json
    // and return its parsed contents as the result.
    NSString *path = [key stringByAppendingPathExtension:@"json"];
    IFFileResource *fileRsc = [_dirResource resourceForPath:path];
    if (fileRsc) {
        return [fileRsc asJSONData];
    }
    return nil;
}

@end

@implementation IFDirmapSchemeHandler

- (id)initWithPath:(NSString *)path {
    self = [super initWithPath:path];
    if (self) {
        _dirmapCache = [NSCache new];
    }
    return self;
}

- (id)dereference:(IFCompoundURI *)uri parameters:(NSDictionary *)params {
    // First check for a previously cached result.
    id dirmap = [_dirmapCache valueForKey:uri.name];
    if (dirmap == [NSNull null]) {
        // Previous directory miss.
        dirmap = nil;
    }
    else if (dirmap == nil) {
        // Result not found, try reading the resource for the named directory.
        id dirResource = [super dereference:uri parameters:params];
        if (dirResource) {
            dirmap = [[IFDirmap alloc] initWithDirectoryResource:dirResource];
        }
        else {
            // Named directory not found; store NSNull to indicate miss.
            dirmap = [NSNull null];
        }
        [_dirmapCache setObject:dirmap forKey:uri.name];
    }
    return dirmap;
}

@end
