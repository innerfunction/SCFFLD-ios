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
//  Created by Julian Goacher on 13/03/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import "SCFileBasedSchemeHandler.h"

@implementation SCFileBasedSchemeHandler

- (id)initWithDirectory:(NSSearchPathDirectory)dirs {
    self = [super init];
    if (self) {
        _paths = NSSearchPathForDirectoriesInDomains( dirs, NSUserDomainMask, YES);
        _fileManager = [NSFileManager defaultManager];
    }
    return self;
}

- (id)initWithPath:(NSString*)path {
    self = [super init];
    if (self) {
        _paths = [NSArray arrayWithObject:path];
        _fileManager = [NSFileManager defaultManager];
    }
    return self;
}

- (id)initWithPath:(NSString *)path extension:(NSString *)ext {
    self = [self initWithPath:path];
    if (path) {
        _extFilter = ext;
    }
    return self;
}

#define IsRelative(uri) (![uri.name hasPrefix:@"/"])

- (SCCompoundURI *)resolve:(SCCompoundURI *)uri against:(SCCompoundURI *)reference {
    if (IsRelative(uri)) {
        uri = [uri copyOf];
        uri.name = [NSString stringWithFormat:@"%@/%@", [reference.name stringByDeletingLastPathComponent], uri.name];
    }
    return uri;
}

- (id)dereference:(SCCompoundURI *)uri parameters:(NSDictionary *)params {
    SCResource* resource = nil;
    for (NSString* path in _paths) {
        resource = [self dereference:uri againstPath:path];
        if (resource) {
            break;
        }
    }
    return resource;
}

- (SCResource *)dereference:(SCCompoundURI *)uri againstPath:(NSString *)path {
    NSString *filePath = [path stringByAppendingPathComponent:uri.name];
    // Append extension filter if extension specified and the path doesn't already have the extension.
    if (_extFilter != nil && ![filePath hasSuffix:[@"." stringByAppendingString:_extFilter]]) {
        filePath = [filePath stringByAppendingPathExtension:_extFilter];
    }
    BOOL isDir;
    BOOL exists = [_fileManager fileExistsAtPath:filePath isDirectory:&isDir];
    if (exists) {
        if (isDir) {
            return [[SCDirectoryResource alloc] initWithPath:filePath uri:uri];
        }
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        NSFileHandle* handle = [NSFileHandle fileHandleForReadingFromURL:fileURL error:nil];
        if (handle) {
            return [[SCFileResource alloc] initWithHandle:handle url:fileURL path:filePath uri:uri];
        }
    }
    return nil;
}

@end
