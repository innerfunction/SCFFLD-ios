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
//  Created by Julian Goacher on 12/03/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import "SCStandardURIHandler.h"
#import "SCStringSchemeHandler.h"
#import "SCFileBasedSchemeHandler.h"
#import "SCLocalSchemeHandler.h"
#import "SCReprSchemeHandler.h"
#import "SCDirmapSchemeHandler.h"
#import "SCResource.h"
#import "SCURIValueFormatter.h"
#import "NSDictionary+SC.h"

@interface SCStandardURIHandler()

- (id)initWithMainBundlePath:(NSString *)mainBundlePath schemeHandlers:(NSMutableDictionary *)schemeHandlers schemeContexts:(NSDictionary *)schemeContexts;
- (SCCompoundURI *)promoteToCompoundURI:(id)uri;

@end

// Internal URI resolver. The resolver is configured with a set of mappings between
// URI scheme names and scheme handlers, which it then uses to resolve compound URIs
// to URI resources.
@implementation SCStandardURIHandler

- (id)init {
    return [self initWithMainBundlePath:MainBundlePath schemeContexts:[NSDictionary dictionary]];
}

- (id)initWithSchemeContexts:(NSDictionary *)schemeContexts {
    return [self initWithMainBundlePath:MainBundlePath schemeContexts:schemeContexts];
}

- (id)initWithMainBundlePath:(NSString *)mainBundlePath schemeContexts:(NSDictionary *)schemeContexts {
    return [self initWithMainBundlePath:mainBundlePath schemeHandlers:[[NSMutableDictionary alloc] init] schemeContexts:schemeContexts];
}

- (id)initWithMainBundlePath:(NSString *)mainBundlePath schemeHandlers:(NSMutableDictionary *)schemeHandlers schemeContexts:(NSDictionary *)schemeContexts {
    self = [super init];
    if (self) {
        _schemeHandlers = schemeHandlers;
        _schemeContexts = schemeContexts;
        // Add standard schemes.
        _schemeHandlers[@"s"] = [SCStringSchemeHandler new];
        // See following for info on iOS file system dirs.
        // https://developer.apple.com/library/mac/#documentation/Cocoa/Reference/Foundation/Miscellaneous/Foundation_Constants/Reference/reference.html
        // http://developer.apple.com/library/ios/#documentation/FileManagement/Conceptual/FileSystemProgrammingGUide/FileSystemOverview/FileSystemOverview.html
        _schemeHandlers[@"app"] = [[SCFileBasedSchemeHandler alloc] initWithPath:mainBundlePath];
        _schemeHandlers[@"cache"] = [[SCFileBasedSchemeHandler alloc] initWithDirectory:NSCachesDirectory];
        _schemeHandlers[@"local"] = [SCLocalSchemeHandler new];
        _schemeHandlers[@"repr"] = [SCReprSchemeHandler new];
        // Load dirmap files from the same location as app:
        _schemeHandlers[@"dirmap"] = [[SCDirmapSchemeHandler alloc] initWithPath:mainBundlePath];
    }
    return self;
}

// Test whether this resolver has a handler for a URI's scheme.
- (BOOL)hasHandlerForURIScheme:(NSString *)scheme {
    return _schemeHandlers[scheme] != nil;
}

// Register a new scheme handler.
- (void)addHandler:(id<SCSchemeHandler>)handler forScheme:(NSString *)scheme {
    _schemeHandlers[scheme] = handler;
}

// Return a list of registered URI scheme names.
- (NSArray *)getURISchemeNames {
    return [_schemeHandlers allKeys];
}

// Return the URI handler for the named scheme.
- (id<SCSchemeHandler>)getHandlerForURIScheme:(NSString *)scheme {
    return _schemeHandlers[scheme];
}

- (id)dereference:(id)uriRef {
    SCCompoundURI *uri = [self promoteToCompoundURI:uriRef];
    id value = nil;
    if (uri) {
        // Resolve a handler for the URI scheme.
        id<SCSchemeHandler> schemeHandler = _schemeHandlers[uri.scheme];
        if (schemeHandler) {
            NSDictionary *params = [self dereferenceParameters:uri];
            // Resolve the current URI to an absolute form (potentially).
            if ([schemeHandler respondsToSelector:@selector(resolve:against:)]) {
                SCCompoundURI *reference = _schemeContexts[uri.scheme];
                if (reference) {
                    uri = [schemeHandler resolve:uri against:reference];
                }
            }
            // Dereference the current URI.
            value = [schemeHandler dereference:uri parameters:params];
        }
        else if ([@"a" isEqualToString:uri.scheme]) {
            // The a: scheme is a pseudo-scheme which is handled by the URI handler rather than a specific
            // scheme handler. Lookup a URI alias and dereference that.
            NSString *aliasedURI = _aliases[uri.name];
            value = [self dereference:aliasedURI];
        }
        else {
            NSString *reason = [NSString stringWithFormat:@"Handler not found for scheme %@:", uri.scheme];
            @throw [[NSException alloc] initWithName:@"SCURIResolver" reason:reason userInfo:nil];
        }
        // If the value is URI context aware then set its URI, and its URI handler as a copy of this handler,
        // with the scheme context modified with the resource's URI.
        if ([value conformsToProtocol:@protocol(SCURIContextAware)]) {
            id<SCURIContextAware> contextAware = (id<SCURIContextAware>)value;
            contextAware.uri = uri;
            contextAware.uriHandler = [self modifySchemeContext:uri];
        }
        // If the URI specifies a formatter then apply it to the URI result.
        if (uri.format) {
            id<SCURIValueFormatter> formatter = _formats[uri.format];
            if (formatter) {
                value = [formatter formatValue:value fromURI:uri];
            }
            else {
                NSString *reason = [NSString stringWithFormat:@"Formatter not found for name %@:", uri.format];
                @throw [[NSException alloc] initWithName:@"SCURIResolver" reason:reason userInfo:nil];
            }
        }
    }
    return value;
}

- (NSDictionary *)dereferenceParameters:(SCCompoundURI *)uri {
    // Dictionary of resolved URI parameters.
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithCapacity:[uri.parameters count]];
    // Iterate over the URIs parameter values (which are also URIs) and dereference each
    // of them.
    for (NSString *name in [uri.parameters allKeys]) {
        SCCompoundURI *valueURI = uri.parameters[name];
        id value = [self dereference:valueURI];
        if (value) {
            params[name] = value;
        }
    }
    return params;
}

- (id<SCURIHandler>)modifySchemeContext:(SCCompoundURI *)uri {
    SCStandardURIHandler *handler = [SCStandardURIHandler new];
    handler->_schemeHandlers = _schemeHandlers;
    handler->_schemeContexts = [_schemeContexts extendWith:@{ uri.scheme: uri }];
    handler.formats = self.formats;
    handler.aliases = self.aliases;
    return handler;
}

- (id<SCURIHandler>)replaceURIScheme:(NSString *)scheme withHandler:(id<SCSchemeHandler>)handler {
    _schemeHandlers[scheme] = handler;
    return self;
}

#pragma mark - private

- (SCCompoundURI *)promoteToCompoundURI:(id)uri {
    if (!uri) {
        return nil;
    }
    if ([uri isKindOfClass:[SCCompoundURI class]]) {
        return (SCCompoundURI *)uri;
    }
    // Attempt to promote the argument to a compound URI by first converting to a string, followed
    // by parsing the string.
    NSError *error;
    NSString *uriString;
    if ([uri isKindOfClass:[NSString class]]) {
        uriString = (NSString *)uri;
    }
    else {
        uriString = [uri description];
    }
    SCCompoundURI *result = [SCCompoundURI parse:uriString error:&error];
    if (error) {
        NSString *reason = [NSString stringWithFormat:@"Error parsing URI %@ code: %ld message: %@", uriString, (long)error.code, [error.userInfo valueForKey:@"message"]];
        @throw [[NSException alloc] initWithName:@"SCURIResolver" reason:reason userInfo:nil];
    }
    return result;
}

#pragma mark - Static methods

static id<SCURIHandler> SCStandardURIHandler_uriHandler;

+ (void)initialize {
    SCStandardURIHandler_uriHandler = [SCStandardURIHandler new];
}

+ (id<SCURIHandler>)uriHandler {
    return SCStandardURIHandler_uriHandler;
}

@end
