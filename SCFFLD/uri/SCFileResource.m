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
//  Created by Julian Goacher on 02/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "SCFileResource.h"
#import "SCTypeConversions.h"

@implementation SCFileDescription

- (id)initWithHandle:(NSFileHandle *)handle url:(NSURL *)url path:(NSString *)path {
    self = [super init];
    self.handle = handle;
    self.url = url;
    self.path = path;
    return self;
}

@end

@implementation SCFileResource

- (id)initWithHandle:(NSFileHandle *)handle url:(NSURL *)url path:(NSString *)filePath uri:(SCCompoundURI *)uri {
    SCFileDescription *fileDesc = [[SCFileDescription alloc] initWithHandle:handle url:url path:filePath];
    self = [super initWithData:fileDesc uri:uri];
    self.fileDescription = fileDesc;
    return self;
}

- (NSString *)asString {
    return [NSString stringWithContentsOfURL:self.fileDescription.url encoding:NSUTF8StringEncoding error:nil];
}

- (NSData *)asData {
    return [self.fileDescription.handle readDataToEndOfFile];
}

- (UIImage *)asImage {
    // First try loading the image by name; this will only work for file based URI schemes, and
    // ensures that the correct version of the image is loaded for the current screen resolution
    // (i.e. @2x @3x) if multiple versions are available.
    NSString *imageName = self.uri.name;
    // Remove any leading slash from the image name (i.e. file path) as [UIImage imageNamed:] won't
    // find the image otherwise.
    if ([imageName hasPrefix:@"/"]) {
        imageName = [imageName substringFromIndex:1];
    }
    // Try loading the image by name.
    UIImage *image = [SCTypeConversions asImage:imageName];
    // Image can't be loaded by name, try loading from file instead.
    if (!image) {
        image = [UIImage imageWithContentsOfFile:self.uri.name];
    }
    // Image can't be loaded by name or from file, try loading using the resource data instead.
    // (Note that this method is probably only useful for subclasses of this resource class that
    // aren't backed by a file on the device file system).
    if (!image) {
        image = [UIImage imageWithData:[self asData]];
    }
    return image;
}

- (id)asJSONData {
    return [SCTypeConversions asJSONData:[self asString]];
}

- (id)asRepresentation:(NSString *)representation {
    if ([@"string" isEqualToString:representation]) {
        return [self asString];
    }
    if ([@"data" isEqualToString:representation]) {
        return [self asData];
    }
    if ([@"image" isEqualToString:representation]) {
        return [self asImage];
    }
    if ([@"json" isEqualToString:representation]) {
        return [self asJSONData];
    }
    if ([@"filepath" isEqualToString:representation]) {
        return self.fileDescription.path;
    }
    return [super asRepresentation:representation];
}

- (NSURL *)externalURL {
    return self.fileDescription.url;
}

@end

@implementation SCDirectoryResource

- (id)initWithPath:(NSString *)path uri:(SCCompoundURI *)uri {
    if (![path hasSuffix:@"/"]) {
        path = [path stringByAppendingString:@"/"];
    }
    self = [super initWithData:path uri:uri];
    self.path = path;
    return self;
}

- (SCFileResource *)resourceForPath:(NSString *)path {
    SCFileResource *result = nil;
    NSString *filePath = [self.path stringByAppendingPathComponent:path];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    BOOL exists = [fileManager fileExistsAtPath:filePath isDirectory:&isDir];
    if (exists && !isDir) {
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        NSFileHandle* handle = [NSFileHandle fileHandleForReadingFromURL:fileURL error:nil];
        if (handle) {
            // Create a URI for the file resource by appending the file path to this resource's URI.
            SCCompoundURI *fileURI = [self.uri copyOf];
            fileURI.name = [fileURI.name stringByAppendingPathComponent:path];
            result = [[SCFileResource alloc] initWithHandle:handle url:fileURL path:filePath uri:fileURI];
            result.uriHandler = self.uriHandler;
        }
    }
    return result;
}

- (NSArray *)list {
    return [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:nil];
}

@end

