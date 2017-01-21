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

- (id)objectForKey:(NSString *)key {
    // Given any key, attempt to load the contents of a file named <key>.json
    // and return its parsed contents as the result.
    NSString *path = [key stringByAppendingPathExtension:@"json"];
    IFFileResource *fileRsc = [_dirResource resourceForPath:path];
    if (fileRsc) {
        // TODO - Return an IFConfiguration instead? to preserve the URI the data has been loaded from.
        // TODO - IFConfiguration really needs an initWithResource: constructor.
        return [fileRsc asJSONData];
    }
    return nil;
}

- (NSUInteger)count {
    return [[self allKeys] count];
}

- (NSEnumerator *)keyEnumerator {
    return [[self allKeys] objectEnumerator];
}

- (NSEnumerator *)objectEnumerator {
    return [[self allValues] objectEnumerator];
}

- (NSArray *)allValues {
    NSArray *keys = [self allKeys];
    NSMutableArray *values = [NSMutableArray new];
    for (NSString *key in keys) {
        id value = [self objectForKey:key];
        [values addObject:value];
    }
    return values;
}

- (NSArray *)allKeys {
    if (_keys == nil) {
        NSArray *files = [_dirResource list];
        // Filter JSON files and extract keys as filename less the .json extension.
        NSMutableArray *keys = [NSMutableArray new];
        for (NSString *filename in files) {
            if ([filename hasSuffix:@".json"]) {
                NSString *key = [filename substringToIndex:[filename length] - 5];
                [keys addObject:key];
            }
        }
        _keys = keys;
    }
    return _keys;
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
        // First create a copy of the current URI, in the app: scheme; this is to ensure that
        // relative URIs in any loaded configurations work as expected.
        IFCompoundURI *dirURI = [[IFCompoundURI alloc] initWithScheme:@"app" uri:uri];
        id dirRsc = [super dereference:dirURI parameters:params];
        if (dirRsc) {
            dirmap = [[IFDirmap alloc] initWithDirectoryResource:dirRsc];
            [_dirmapCache setObject:dirmap forKey:uri.name];
        }
        else {
            // Named directory not found; store NSNull to indicate miss.
            [_dirmapCache setObject:[NSNull null] forKey:uri.name];
        }
    }
    return dirmap;
}

@end
