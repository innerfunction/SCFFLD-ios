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

#import "SCIOCConfiguration.h"
#import "SCRegExp.h"
#import "SCStringTemplate.h"
#import "SCTypeConversions.h"
#import "SCStandardURIHandler.h"
#import "NSDictionary+SC.h"
#import "UIColor+SC.h"
#import "SCJSONData.h"

#define ValueOrDefault(v,dv) (v == nil ? dv : v)

// Normalize the reference to _topLevelConfig for a new configuration object derived from the current.
// The _topLevelConfig reference is a weak reference and so needs special handling when normalizing or
// extending a configuration, as the configuration the result is derived from might be an
// intermediate result itself, and so can be lost at a later point. The solution is to
// check whether the source configuration's _topLevelConfig is a reference to self - if it is, then
// use a reference to the new configuration in its place.
#define NormalizedRootRef(cfg)  ((self == _topLevelConfig) ? cfg : _topLevelConfig)

@interface SCArrayBackedDictionary : NSDictionary {
    NSNumberFormatter *_numParser;
}

@property (nonatomic, strong) NSArray *array;

- (id)initWithArray:(NSArray *)array;

@end

@interface SCIOCConfiguration()

- (id)initWithConfiguration:(id<SCConfiguration>)config mixin:(id<SCConfiguration>)mixin parent:(id<SCConfiguration>)parent;
- (void)initializeContext;

@end

@implementation SCIOCConfiguration

@synthesize configData=_configData,
            sourceData=_sourceData,
            topLevelConfig=_topLevelConfig,
            dataContext=_dataContext,
            uriHandler=_uriHandler;

- (id)init {
    // Initialize with an empty dictionary.
    self = [super init];
    self.configData = [NSDictionary dictionary];
    self.topLevelConfig = self;
    self.uriHandler = [SCStandardURIHandler uriHandler]; // Use the global URI handler.
    [self initializeContext];
    return self;
}

- (id)initWithData:(id)data {
    self = [self initWithData:data parent:[SCIOCConfiguration emptyConfiguration]];
    self.topLevelConfig = self;
    return self;
}

- (id)initWithResource:(SCResource *)resource {
    self = [self initWithData:[resource asJSONData]];
    if (self) {
        self.uriHandler = resource.uriHandler;
        [self initializeContext];
    }
    return self;
}

- (id)initWithData:(id)data parent:(id<SCConfiguration>)parent {
    self = [super init];
    if (self) {
        if ([data isKindOfClass:[NSString class]]) {
            self.configData = [SCTypeConversions asJSONData:data];
        }
        else {
            self.configData = data;
        }
        self.topLevelConfig = parent.topLevelConfig;
        self.dataContext = parent.dataContext;
        self.uriHandler = parent.uriHandler;
        [self initializeContext];
    }
    return self;
}

- (id)initWithConfiguration:(id<SCConfiguration>)config mixin:(id<SCConfiguration>)mixin parent:(id<SCConfiguration>)parent {
    self = [super init];
    if (self) {
        self.configData = [config.configData extendWith:mixin.configData];
        self.dataContext = [config.dataContext extendWith:mixin.dataContext];
        self.topLevelConfig = parent.topLevelConfig;
        self.sourceData = parent.sourceData;
        self.uriHandler = parent.uriHandler;
        [self initializeContext];
    }
    return self;
}

- (void)setConfigData:(id)data {
    _sourceData = data;
    if ([data isKindOfClass:[NSArray class]]) {
        _configData = [[SCArrayBackedDictionary alloc] initWithArray:(NSArray *)data];
    }
    else if([data isKindOfClass:[NSDictionary class]]) {
        _configData = (NSDictionary *)data;
    }
}

- (void)initializeContext {
    NSMutableDictionary *params = [NSMutableDictionary new];
    NSMutableDictionary *values = [NSMutableDictionary new];
    // Search the configuration data for any parameter values, filter parameter values out of main data values.
    for (NSString *name in [_configData allKeys]) {
        if ([name hasPrefix:@"$"]) {
            params[name] = _configData[name];
        }
        else {
            values[name] = _configData[name];
        }
    }
    // Initialize/modify the context with parameter values, if any.
    if ([params count]) {
        if (self.dataContext) {
            self.dataContext = [self.dataContext extendWith:params];
        }
        else {
            self.dataContext = params;
        }
        self.configData = values;
    }
    else if (!self.dataContext) {
        self.dataContext = [NSDictionary dictionary];
    }
}

- (id<SCConfiguration>)asConfiguration:(id)value {
    // If value is already a configuration then return as is.
    if ([value conformsToProtocol:@protocol(SCConfiguration)]) {
        return (id<SCConfiguration>)value;
    }
    // Try to resolve configuration data from the argument.
    id dataValue = value;
    SCResource *valueRsc = nil;
    // If value is a resource then try converting to JSON data.
    if ([value isKindOfClass:[SCResource class]]) {
        valueRsc = (SCResource *)value;
        dataValue = [valueRsc asJSONData];
    }
    // If value isn't a configuration by this point then promote to a new config,
    // providing data is one of the supported types.
    BOOL isConfigDataType = [dataValue isKindOfClass:[NSDictionary class]]
                         || [dataValue isKindOfClass:[NSArray class]];
    if (isConfigDataType) {
        SCIOCConfiguration *configValue = [[SCIOCConfiguration alloc] initWithData:dataValue parent:self];
        // NOTE When the configuration data is sourced from a resource, then the
        // following properties need to be different from when the data is found
        // directly in the configuration:
        // * root: The resource defines a new context for # refs, so root needs to
        //   point to the new config.
        // * uriHandler: The resource's handler needs to be used, so that any
        //   relative URIs within the resource data resolve correctly.
        if (valueRsc != nil) {
            configValue.topLevelConfig = configValue;
            configValue.uriHandler = valueRsc.uriHandler;
        }
        return [configValue normalize];
    }
    // Can't resolve a configuration so return nil.
    return nil;
}

- (id)getValue:(NSString*)keyPath asRepresentation:(NSString *)representation {
    id value = _configData;
    NSArray *components = [keyPath componentsSeparatedByString:@"."];
    for (NSString *key in components) {
        // Unpack any resource value.
        if ([value isKindOfClass:[SCResource class]]) {
            value = [(SCResource *)value asJSONData];
        }
        // Lookup the key value on the current object.
        if ([value isKindOfClass:[NSArray class]]) {
            NSInteger idx = [key integerValue];
            value = value[idx];
        }
        else if ([value respondsToSelector:@selector(objectForKey:)]) {
            value = value[key];
        }
        else {
            value = nil;
        }
        // Continue if we have a value, else break out of the loop.
        if (value != nil) {
            // Modify the value by accounting for any value prefixes.
            if ([value isKindOfClass:[NSString class]]) {
                // Interpret the string value.
                NSString* valueStr = (NSString *)value;
                // First, attempt resolving any context references. If these in turn resolve to a
                // $ or # prefixed value, then they will be resolved in the following code.
                if ([valueStr hasPrefix:@"$"]) {
                    value = _dataContext[valueStr];
                    // If context value is also a string then continue to following modifiers...
                    if ([value isKindOfClass:[NSString class]]) {
                        valueStr = (NSString *)value;
                    }
                    else {
                        // ...else continue to next key.
                        continue;
                    }
                }
                // Evaluate any string beginning with ? or > as a string template.
                if ([valueStr hasPrefix:@"?"] || [valueStr hasPrefix:@">"]) {
                    valueStr = [valueStr substringFromIndex:1];
                    valueStr = [SCStringTemplate render:valueStr context:_dataContext];
                }
                // String values beginning with @ are internal URI references, so dereference the URI.
                if ([valueStr hasPrefix:@"@"]) {
                    NSString *uri = [valueStr substringFromIndex:1];
                    value = [_uriHandler dereference:uri];
                }
                // Any string values starting with a '#' are potential path references to other
                // properties in the same configuration. Attempt to resolve them against the configuration
                // root; if they don't resolve then return the original value.
                else if ([valueStr hasPrefix:@"#"]) {
                    value = [_topLevelConfig getValue:[valueStr substringFromIndex:1] asRepresentation:representation];
                    if (value == nil) {
                        // If no value resolved then reset value to the #string
                        value = valueStr;
                    }
                }
                else if ([valueStr hasPrefix:@"`"]) {
                    value = [valueStr substringFromIndex:1];
                }
                else if (valueStr) {
                    value = valueStr;
                }
            }
        }
        else {
            break;
        }
    }
    
    // If something other than the raw representation is required then try to convert:
    // * configuration: See the asConfiguration: method;
    // * all other representations are passed to TypeConversions.
    if (![@"raw" isEqualToString:representation]) {
        if ([@"configuration" isEqualToString:representation]) {
            value = [self asConfiguration:value];
        }
        else if ([value isKindOfClass:[SCResource class]]) {
            value = [(SCResource *)value asRepresentation:representation];
        }
        else {
            value = [SCTypeConversions value:value asRepresentation:representation];
        }
    }
    return value;
}

- (BOOL)hasValue:(NSString *)keyPath {
    return [self getValue:keyPath asRepresentation:@"raw"] != nil;
}

- (NSString *)getValueAsString:(NSString *)keyPath {
    return [self getValueAsString:keyPath defaultValue:nil];
}

- (NSString *)getValueAsString:(NSString*)keyPath defaultValue:(NSString*)defaultValue {
    NSString* value = [self getValue:keyPath asRepresentation:@"string"];
    return value == nil || ![value isKindOfClass:[NSString class]] ? defaultValue : value;
}

- (NSString *)getValueAsLocalizedString:(NSString *)keyPath {
    NSString *value = [self getValueAsString:keyPath];
    return value == nil ? nil : NSLocalizedString(value, @"");
}

- (NSNumber *)getValueAsNumber:(NSString *)keyPath {
    return [self getValueAsNumber:keyPath defaultValue:nil];
}

- (NSNumber *)getValueAsNumber:(NSString*)keyPath defaultValue:(NSNumber*)defaultValue {
    NSNumber* value = [self getValue:keyPath asRepresentation:@"number"];
    return value == nil || ![value isKindOfClass:[NSNumber class]] ? defaultValue : value;
}

- (BOOL)getValueAsBoolean:(NSString *)keyPath {
    return [self getValueAsBoolean:keyPath defaultValue:NO];
}

- (BOOL)getValueAsBoolean:(NSString*)keyPath defaultValue:(BOOL)defaultValue {
    NSNumber* value = [self getValue:keyPath asRepresentation:@"number"];
    return value == nil ? defaultValue : [value boolValue];
}

// Resolve a date value on the cell data at the specified path.
- (NSDate *)getValueAsDate:(NSString *)keyPath {
    return [self getValueAsDate:keyPath defaultValue:nil];
}

// Resolve a date value on the cell data at the specified path, return the default value if not set.
- (NSDate *)getValueAsDate:(NSString *)keyPath defaultValue:(NSDate *)defaultValue {
    NSDate *value = [self getValue:keyPath asRepresentation:@"date"];
    return value == nil || ![value isKindOfClass:[NSDate class]] ? defaultValue : value;
}

- (UIColor *)getValueAsColor:(NSString *)keyPath {
    NSString *hexValue = [self getValueAsString:keyPath];
    return hexValue ? [UIColor colorForHex:hexValue] : nil;
}

- (UIColor *)getValueAsColor:(NSString *)keyPath defaultValue:(UIColor *)defaultValue {
    return ValueOrDefault([self getValueAsColor:keyPath], defaultValue);
}

- (NSURL *)getValueAsURL:(NSString *)keyPath {
    NSURL *value = [self getValue:keyPath asRepresentation:@"url"];
    return [value isKindOfClass:[NSURL class]] ? value : nil;
}

- (NSData *)getValueAsData:(NSString *)keyPath {
    NSData *value = [self getValue:keyPath asRepresentation:@"data"];
    return [value isKindOfClass:[NSData class]] ? value : nil;
}

- (UIImage *)getValueAsImage:(NSString *)keyPath {
    UIImage *value = [self getValue:keyPath asRepresentation:@"image"];
    return [value isKindOfClass:[UIImage class]] ? value : nil;
}

- (id)getValue:(NSString *)keyPath {
    return [self getValue:keyPath asRepresentation:@"raw"];
}

- (id)getValueAsJSONData:(NSString *)keyPath {
    id value = [self getValue:keyPath asRepresentation:@"raw"];
    if ([value isKindOfClass:[SCResource class]]) {
        value = [(SCResource *)value asJSONData];
    }
    if ([value isKindOfClass:[NSDictionary class]]) {
        value = [[SCJSONObject alloc] initWithDictionary:(NSDictionary *)value];
    }
    else if ([value isKindOfClass:[NSArray class]]) {
        value = [[SCJSONArray alloc] initWithArray:(NSArray *)value];
    }
    return value;
}

- (NSArray *)getValueNames {
    return [_configData allKeys];
}

- (id<SCConfiguration>)getValueAsConfiguration:(NSString *)keyPath {
    return [[self getValue:keyPath asRepresentation:@"configuration"] normalize];
}

- (id<SCConfiguration>)getValueAsConfiguration:(NSString *)keyPath defaultValue:(id<SCConfiguration>)defaultValue {
    return ValueOrDefault([self getValueAsConfiguration:keyPath], defaultValue);
}

- (NSArray *)getValueAsConfigurationList:(NSString *)keyPath {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    id value = [self getValue:keyPath];
    if ([value isKindOfClass:[NSArray class]]) {
        NSArray *valuesArray = (NSArray *)value;
        if (![valuesArray isKindOfClass:[NSArray class]]) {
            valuesArray = [self getValue:keyPath asRepresentation:@"json"];
        }
        if ([valuesArray isKindOfClass:[NSArray class]]) {
            for (NSInteger i = 0; i < [valuesArray count]; i++) {
                NSString *itemKeyPath = [NSString stringWithFormat:@"%@.%ld", keyPath, (long)i];
                id<SCConfiguration> item = [self getValueAsConfiguration:itemKeyPath];
                [result addObject:item];
            }
        }
    }
    return result;
}

- (NSDictionary *)getValueAsConfigurationMap:(NSString *)keyPath {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    id values = [self getValue:keyPath];
    if ([values isKindOfClass:[NSDictionary class]]) {
        NSDictionary *valuesDictionary = (NSDictionary *)values;
        for (id key in [valuesDictionary allKeys]) {
            NSString *itemKeyPath = [NSString stringWithFormat:@"%@.%@", keyPath, key];
            id<SCConfiguration> item = [self getValueAsConfiguration:itemKeyPath];
            [result setObject:item forKey:key];
        }
    }
    return result;
}

- (id<SCConfiguration>)mixinConfiguration:(id<SCConfiguration>)otherConfig {
    return [[SCIOCConfiguration alloc] initWithConfiguration:self mixin:otherConfig parent:self];
}

- (id<SCConfiguration>)mixoverConfiguration:(id<SCConfiguration>)otherConfig {
    return [[SCIOCConfiguration alloc] initWithConfiguration:otherConfig mixin:self parent:self];
}

- (id<SCConfiguration>)extendWithParameters:(NSDictionary *)params {
    id<SCConfiguration> result = self;
    if ([params count] > 0) {
        NSMutableDictionary *$params = [NSMutableDictionary new];
        for (NSString *key in [params allKeys]) {
            NSString *$key = [NSString stringWithFormat:@"$%@", key];
            $params[$key] = params[key];
        }
        result = [[SCIOCConfiguration alloc] initWithData:_configData parent:self];
        result.dataContext = [result.dataContext extendWith:$params];
    }
    return result;
}

- (id<SCConfiguration>)flatten {
    id<SCConfiguration> result = self;
    id<SCConfiguration> mixin = [self getValueAsConfiguration:@"-config"];
    if (mixin) {
        result = [self mixinConfiguration:mixin];
    }
    mixin = [self getValueAsConfiguration:@"-mixin"];
    if (mixin) {
        result = [self mixinConfiguration:mixin];
    }
    NSArray *mixins = [self getValueAsConfigurationList:@"-mixins"];
    if (mixins) {
        for (id<SCConfiguration> mixin in mixins) {
            result = [self mixinConfiguration:mixin];
        }
    }
    return result;
}

- (id<SCConfiguration>)normalize {
    // Build a hierarchy of configurations extended by other configs.
    NSMutableArray *hierarchy = [NSMutableArray new];
    id<SCConfiguration> current = [self flatten];
    [hierarchy addObject:current];
    while ((current = [current getValueAsConfiguration:@"-extends"]) != nil) {
        current = [current flatten];
        if ([hierarchy containsObject:current]) {
            // Extension loop detected, stop extending the config.
            break;
        }
        [hierarchy addObject:current];
    }
    // Build a single unified configuration from the hierarchy of configs.
    id<SCConfiguration> result = [SCIOCConfiguration emptyConfiguration];
    // Process the hierarchy in reverse order (i.e. from most distant ancestor to current config).
    for (id<SCConfiguration> config in [hierarchy reverseObjectEnumerator]) {
        result = [[SCIOCConfiguration alloc] initWithConfiguration:result mixin:config parent:result];
    }
    result.sourceData = _sourceData;
    result.topLevelConfig = NormalizedRootRef(result);
    result.uriHandler = _uriHandler;
    return result;
}

- (id<SCConfiguration>)configurationWithKeysExcluded:(NSArray *)excludedKeys {
    NSDictionary *data = [_configData dictionaryWithKeysExcluded:excludedKeys];
    id<SCConfiguration> result = [[SCIOCConfiguration alloc] initWithData:data];
    result.sourceData = _sourceData;
    result.topLevelConfig = NormalizedRootRef(result);
    result.dataContext = _dataContext;
    result.uriHandler = _uriHandler;
    return result;
}

- (BOOL)isEqual:(id)object {
    // Two configurations are equal if the have the same source resource.
    return [object isKindOfClass:[SCIOCConfiguration class]] && [_configData isEqual:((SCIOCConfiguration *)object).configData];
}

static SCIOCConfiguration *emptyConfiguaration;

+ (void)initialize {
    emptyConfiguaration = [SCIOCConfiguration new];
}

+ (id<SCConfiguration>)emptyConfiguration {
    return emptyConfiguaration;
}

@end

// NSDictionary interface backed by an NSArray
@implementation SCArrayBackedDictionary

- (id)initWithArray:(NSArray *)array {
    self = [super init];
    if (self) {
        _array = array;
        _numParser = [NSNumberFormatter new];
    }
    return self;
}

- (NSUInteger)count {
    return [_array count];
}

- (id)objectForKey:(id)aKey {
    // TODO: Need to test whether [_array valueForKey:aKey] will return the same result.
    NSNumber *num = [_numParser numberFromString:[aKey description]];
    NSInteger idx = num != nil ? num.integerValue : -1;
    return idx > -1 && idx < [_array count] ? [_array objectAtIndex:idx] : nil;
}

- (NSEnumerator *)keyEnumerator {
    NSMutableArray *keys = [[NSMutableArray alloc] initWithCapacity:[_array count]];
    for (NSInteger idx = 0; idx < [_array count]; idx++) {
        NSString *key = [[NSNumber numberWithInteger:idx] description];
        [keys addObject:key];
    }
    return [keys objectEnumerator];
}

@end
