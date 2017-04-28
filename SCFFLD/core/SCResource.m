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
//  Created by Julian Goacher on 17/03/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import "SCResource.h"
#import "SCCompoundURI.h"
#import "SCTypeConversions.h"

// Standard URI resource. Recognizes NSString, NSNumber and NSData resource types
// and resolves different representations appropriately.
@implementation SCResource

@synthesize uri=_uri, uriHandler=_uriHandler;

- (id)initWithData:(id)data uri:(SCCompoundURI *)uri {
    self = [super init];
    self.data = data;
    self.uri = uri;
    return self;
}

#pragma mark - representation methods

- (BOOL)asBoolean {
    return [SCTypeConversions asBoolean:[self asDefault]];
}

- (id)asDefault {
    return _data;
}

- (UIImage *)asImage {
    return [SCTypeConversions asImage:[self asDefault]];
}

// Access the resource's JSON representation.
// Returns the string representation parsed as a JSON string.
- (id)asJSONData {
    return [SCTypeConversions asJSONData:[self asDefault]];
}

- (NSNumber *)asNumber {
    return [SCTypeConversions asNumber:[self asDefault]];
}

// Access the resource's string representation.
- (NSString *)asString {
    return [SCTypeConversions asString:[self asDefault]];
}

- (NSData *)asData {
    return [SCTypeConversions asData:[self asDefault]];
}

- (NSURL *)asURL {
    return [SCTypeConversions asURL:[self asDefault]];
}

/* TODO: There is only one call to this method, if SCTableViewController; remove
   this once done.
- (SCConfiguration *)asConfiguration {
    return [[SCConfiguration alloc] initWithResource:self];
}
*/

- (id)asRepresentation:(NSString *)representation {
    return [SCTypeConversions value:[self asDefault] asRepresentation:representation];
}

- (NSURL *)externalURL {
    return nil;
}

- (SCResource *)refresh {
    return (SCResource *)[self.uriHandler dereference:self.uri];
}

#pragma mark - NSObject overrides

- (NSString *)description {
    return [self asString];
}

- (NSUInteger)hash {
    return self.uri ? [self.uri hash] : [super hash];
}

- (BOOL)isEqual:(id)object {
    return [object isKindOfClass:[SCResource class]] && [self.uri isEqual:((SCResource *)object).uri];
}

@end