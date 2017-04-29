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
//  Created by Julian Goacher on 06/04/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "SCObjectConfigurer.h"
#import "SCIOCContainer.h"
#import "SCIOCConfigurationAware.h"
#import "SCIOCTypeInspectable.h"
#import "SCIOCObjectFactory.h"
#import "SCIOCObjectAware.h"
#import "SCIOCProxy.h"
#import "SCPendingNamed.h"

@interface SCObjectConfigurer ()

/// Normalize a property name by removing any -ios prefix. Returns nil for reserved names (e.g. -type etc.)
- (NSString *)normalizePropertyName:(NSString *)name;

@end

/// A version of SCTypeInfo that returns type information for a collection's members.
@interface SCCollectionTypeInfo : SCTypeInfo {
    /// The default type of each member of the collection.
    SCPropertyInfo *_memberTypeInfo;
}

/**
 * Init the object.
 * @param collection    The collection.
 * @param parent        The collection's parent object.
 * @param propName      The name of the property the collection is bound to on its parent object.
 */
- (id)initWithCollection:(id)collection parent:(id)parent propName:(NSString *)propName;

@end

/// A version of SCTypeInfo that handles undeclared named properties of a collection.
@interface SCContainerTypeInfo : SCTypeInfo

- (id)initWithContainer:(SCIOCContainer *)container;

@end

@implementation SCObjectConfigurer

- (id)initWithContainer:(SCIOCContainer *)container {
    self = [super init];
    if (self) {
        _container = container;
        _containerTypeInfo = [[SCContainerTypeInfo alloc] initWithContainer:_container];
        _logger = [[SCLogger alloc] initWithTag:@"SCObjectConfigurer"];
    }
    return self;
}

- (void)configureWith:(id<SCConfiguration>)configuration {
    [self configureObject:_container withConfiguration:configuration typeInfo:_containerTypeInfo keyPathPrefix:nil];
}

- (id)configureNamed:(NSString *)name withConfiguration:(id<SCConfiguration>)configuration {
    SCPropertyInfo *propInfo = [_containerTypeInfo infoForProperty:name];
    id named = [self buildValueForObject:_container
                                property:name
                       withConfiguration:configuration
                                propInfo:propInfo
                              keyPathRef:name];
    if (named != nil) {
        [self injectIntoObject:_container value:named intoProperty:name propInfo:propInfo];
    }
    return named;
}

- (void)configureObject:(id)object withConfiguration:(id<SCConfiguration>)configuration keyPathPrefix:(NSString *)kpPrefix {
    // If value is an NSDictionary or NSArray then get a mutable copy.
    // Also, whilst at it - get type information for the object.
    SCTypeInfo *typeInfo = [SCTypeInfo typeInfoForObject:object];
    [self configureObject:object withConfiguration:configuration typeInfo:typeInfo keyPathPrefix:kpPrefix];
}

- (void)configureObject:(id)object
      withConfiguration:(id<SCConfiguration>)configuration
               typeInfo:(SCTypeInfo *)typeInfo
          keyPathPrefix:(NSString *)kpPrefix {

    // Pre-configuration.
    if ([object conformsToProtocol:@protocol(SCIOCConfigurationAware)]) {
        [(id<SCIOCConfigurationAware>)object beforeIOCConfiguration:configuration];
    }
    // Iterate over each property name defined in the configuration.
    NSArray *valueNames = [configuration getValueNames];
    for (NSString *name in valueNames) {
        // Normalize the property name.
        NSString *propName = [self normalizePropertyName:name];
        if (propName) {
            // Get type info for the property.
            SCPropertyInfo *propInfo = [typeInfo infoForProperty:propName];
            if (!propInfo) {
                // If no type info then can't process this property any further.
                continue;
            }
            // Generate a key path reference for the property.
            NSString *kpRef;
            if (kpPrefix) {
                kpRef = [NSString stringWithFormat:@"%@.%@", kpPrefix, propName];
            }
            else {
                kpRef = propName;
            }
            // Build a property value from the configuration.
            id value = [self buildValueForObject:object
                                        property:propName
                               withConfiguration:configuration
                                        propInfo:propInfo
                                      keyPathRef:kpRef];
            // If there is a value by this stage then inject into the object.
            if (value != nil) {
                @try {
                    value = [self injectIntoObject:object value:value intoProperty:propName propInfo:propInfo];
                }
                @catch (id exception) {
                    [_logger error:@"Error injecting value into %@: %@", kpRef, exception];
                }
            }
        }
    }
    // Post configuration.
    if ([object conformsToProtocol:@protocol(SCIOCConfigurationAware)]) {
        NSValue *objectKey = [NSValue valueWithNonretainedObject:object];
        if ([_container hasPendingValueRefsForObjectKey:objectKey]) {
            [_container recordPendingValueObjectConfiguration:configuration forObjectKey:objectKey];
        }
        else {
            [(id<SCIOCConfigurationAware>)object afterIOCConfiguration:configuration];
        }
    }
    [_container doPostConfiguration:object];
}

#define PropInfoIsCollectionType(propInfo)  ([propInfo isSubclassOf:[NSDictionary class]] || [propInfo isSubclassOf:[NSArray class]])

- (id)buildValueForObject:(id)object
                 property:(NSString *)propName
        withConfiguration:(id<SCConfiguration>)configuration
                 propInfo:(SCPropertyInfo *)propInfo
               keyPathRef:(NSString *)kpRef {
    
    id value = nil;
    
    // First, check to see if the property belongs to one of the standard types used to
    // represent primitive configurable values. These values are different to other
    // non-primitive types, in that (1) it's generally possible to convert values between them,
    // and (2) the code won't recursively perform any additional configuration on the values.
    if (![propInfo isId]) {
        // Primitives and core types.
        if ([propInfo isBoolean]) {
            value = [NSNumber numberWithBool:[configuration getValueAsBoolean:propName]];
        }
        else if ([propInfo isInteger]) {
            value = [configuration getValueAsNumber:propName];
        }
        else if ([propInfo isFloat]) {
            value = [configuration getValueAsNumber:propName];
        }
        else if ([propInfo isDouble]) {
            value = [configuration getValueAsNumber:propName];
        }
        else if ([propInfo isSubclassOf:[NSNumber class]]) {
            value = [configuration getValueAsNumber:propName];
        }
        else if ([propInfo isSubclassOf:[NSString class]]) {
            value = [configuration getValueAsString:propName];
        }
        else if ([propInfo isSubclassOf:[NSDate class]]) {
            value = [configuration getValueAsDate:propName];
        }
        else if ([propInfo isSubclassOf:[UIImage class]]) {
            value = [configuration getValueAsImage:propName];
        }
        else if ([propInfo isSubclassOf:[UIColor class]]) {
            value = [configuration getValueAsColor:propName];
        }
        else if ([propInfo isConformantTo:@protocol(SCConfiguration)]) {
            value = [configuration getValueAsConfiguration:propName];
        }
        else if (PropInfoIsCollectionType(propInfo) && [object conformsToProtocol:@protocol(SCIOCTypeInspectable)]) {
            // The current property is a collection type (i.e. dictionary or list); test whether it accepts
            // raw JSON values, and if so then set the value to the raw, unparsed JSON configuration value.
            NSDictionary *typeInfo = [(id<SCIOCTypeInspectable>)object collectionMemberTypeInfo];
            if (typeInfo) {
                id type = typeInfo[propName];
                if (type == @protocol(SCJSONValue)) {
                    value = [configuration getValueAsJSONData:propName];
                }
            }
        }
    }
    
    // If value is still nil then the property is not a primitive or JSON data type. Try to
    // resolve a new value from the supplied configuration.
    // The configuration may contain a mixture of object definitions and fully instantiated
    // objects. The configuration's 'natural' representation will distinguish between these,
    // return a Configuration instance for object definitions and the actual object instance
    // otherwise.
    // When an object definition is returned, the property value is resolved according to the
    // following order of precedence:
    // 1. A configuration which supplies an instantiation hint - e.g. -type, -ios-class or
    //    @factory - and which successfully yields an object instance always takes precedence
    //    over other possible values;
    // 2. Next, any in-place value found by reading from the object property being configured;
    // 3. Finally, a value created by attempting to instantiate the declared type of the
    //    property being configured (i.e. the inferred type).
    if (value == nil) {
        // Fetch the raw configuration data.
        id rawValue = [configuration getValue:propName];
        // Try converting the raw value to a configuration object.
        id<SCConfiguration> valueConfig = [configuration asConfiguration:rawValue];
        // If this works the try using it to resolve an actual property value.
        if (valueConfig) {
            // Try asking the container to build a new object using the configuration. This
            // will only work if the configuration contains an instantiation hint (e.g. -type,
            // @factory etc.) and will return a non-null, fully-configured object if successful.
            value = [_container buildObjectWithConfiguration:valueConfig identifier:kpRef];
            if (value == nil) {
                // Couldn't build a value, so see if the object already has a value in-place.
                if ([object isKindOfClass:[NSArray class]]) {
                    // Read the nth item from the object array. Note that if propName isn't a valid
                    // integer then idx will be 0, and the first array item (if any) will always be read.
                    NSInteger idx = [propName integerValue];
                    NSArray *array = (NSArray *)object;
                    if (idx < [array count]) {
                        value = [array objectAtIndex:idx];
                    }
                }
                else {
                    @try {
                        value = [object valueForKey:propName];
                    }
                    @catch (NSException *e) {
                        if ([object isKindOfClass:[NSDictionary class]] && [@"NSUnknownKeyException" isEqualToString:e.name]) {
                            // Ignore: Can happen when e.g. configuring the container with named objects which
                            // aren't properties of the container.
                        }
                        else {
                            [_logger error:@"Reading %@ %@", kpRef, e];
                        }
                    }
                }
                if (value != nil) {
                    // Apply configuration proxy wrapper, if any defined, to the in-place value.
                    value = [SCIOCContainer applyConfigurationProxyWrapper:value];
                }
                else if (![propInfo isId]) {
                    // No in-place value, so try inferring a value type from the property
                    // information, and then try to instantiate that type as the new value.
                    // (Note that the container method will return a configuration proxy for
                    // those classes which require one.)
                    __unsafe_unretained Class propClass = [propInfo getPropertyClass];
                    NSString *className = NSStringFromClass(propClass);
                    @try {
                        value = [_container newInstanceForClassName:className withConfiguration:valueConfig];
                    }
                    @catch (NSException *e) {
                        [_logger error:@"Error creating new instance of inferred type %@: %@", className, e ];
                    }
                }
                // If we now have either an in-place or inferred type value by this point, then
                // continue by configuring the object with its configuration.
                if (value != nil) {
                    // If value is an NSDictionary or NSArray then get a mutable copy.
                    // Also, whilst at it - get type information for the object.
                    SCTypeInfo *typeInfo;
                    if ([value isKindOfClass:[NSDictionary class]]) {
                        @try {
                            value = [(NSDictionary *)value mutableCopy];
                        }
                        @catch (id exception) {
                            [_logger error:@"Unable to make mutable NSDictionary copy of %@", kpRef];
                        }
                        typeInfo = [[SCCollectionTypeInfo alloc] initWithCollection:value parent:object propName:propName];
                    }
                    else if ([value isKindOfClass:[NSArray class]]) {
                        @try {
                            value = [(NSArray *)value mutableCopy];
                        }
                        @catch (id exception) {
                            [_logger error:@"Unable to make mutable NSArray copy of %@", kpRef];
                        }
                        typeInfo = [[SCCollectionTypeInfo alloc] initWithCollection:value parent:object propName:propName];
                    }
                    else {
                        typeInfo = [SCTypeInfo typeInfoForObject:value];
                    }
                    // Configure the value.
                    [self configureObject:value withConfiguration:valueConfig typeInfo:typeInfo keyPathPrefix:kpRef];
                }
            }
        }
        if (value == nil) {
            // If still no value at this point then the config either contains a realised value, or the config data can't
            // be used to resolve a new value.
            // TODO: Some way to convert raw values directly to required object types? e.g. String -> Number
            // e.g. [SCValueConversions convertValue:rawValue toPropertyType:propInfo]
            value = rawValue;
        }
    }
    return value;
}

- (id)injectIntoObject:(id)object value:(id)value intoProperty:(NSString *)name propInfo:(SCPropertyInfo *)propInfo {
    // Notify object aware values that they are about to be injected into the object under the current property name.
    // NOTE: This happens at this point - instead of after the value injection - so that value proxies can receive the
    // notification. It's more likely that proxies would implement this protocol than the values they act as proxy for
    // (i.e. because proxied values are likely to be standard platform classes).
    if ([value conformsToProtocol:@protocol(SCIOCObjectAware)]) {
        [(id<SCIOCObjectAware>)value notifyIOCObject:object propertyName:name];
    }
    // If value is a config proxy then unwrap the underlying value
    if ([value conformsToProtocol:@protocol(SCIOCProxy)]) {
        value = [(id<SCIOCProxy>)value unwrapValue];
    }
    // If value is a pending then defer operation until later.
    if ([value isKindOfClass:[SCPendingNamed class]]) {
        // Record the current property and object info, but skip further processing. The property value will be set
        // once the named reference is fully configured, see [SCContainer buildNamedObject:].
        SCPendingNamed *pending = (SCPendingNamed *)value;
        pending.key = name;
        pending.configurer = self;
        pending.object = object;
        pending.propInfo = propInfo;
        // Keep count of the number of pending value refs for the current object.
        [_container incPendingValueRefCountForPendingObject:pending];
    }
    else if (value != nil && [propInfo isWriteable] && [propInfo isAssignableFrom:[value class]]) {
        if ([value isKindOfClass:[NSArray class]]) {
            // If value is an array then filter out any NSNull values; these are inserted by the code
            // below to pad intermediate values when initially populating the array.
            // Alternative behaviour here would be to wrap the array value in an NSArray subclass,
            // which overrides the objectAtIndex: method to return nil when the in-place value is NSNull.
            value = [(NSArray *)value filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nonnull object, NSDictionary<NSString *,id> * _Nullable bindings) {
                return object != [NSNull null];
            }]];
        }
        // Check for dictionary or map collections...
        if ([object isKindOfClass:[NSDictionary class]]) {
            // Dictionary collection entry.
            object[name] = value;
        }
        else if ([object isKindOfClass:[NSArray class]]) {
            // Array item.
            NSMutableArray *array = (NSMutableArray *)object;
            NSInteger idx = [name integerValue];
            // Add null items to pad array to the required length.
            for (NSInteger j = [array count]; j < idx + 1; j++) {
                [array addObject:[NSNull null]];
            }
            array[idx] = value;
        }
        else {
            // ...configuring an standard object property.
            [object setValue:value forKey:name];
        }
    }
    return value;
}

#pragma mark - Private methods

- (NSString *)normalizePropertyName:(NSString *)name {
    if ([name hasPrefix:@"-"]) {
        if ([name hasPrefix:@"-ios:"]) {
            // Strip -ios prefix from names.
            name = [name substringFromIndex:5];
            // Don't process class names.
            if ([@"-class" isEqualToString:name]) {
                name = nil;
            }
        }
        else {
            name = nil; // Skip all other reserved names
        }
    }
    return name;
}

@end

@implementation SCCollectionTypeInfo

- (id)initWithCollection:(id)collection parent:parent propName:(NSString *)propName {
    self = [super init];
    if (self) {
        if ([parent conformsToProtocol:@protocol(SCIOCTypeInspectable)]) {
            NSDictionary *typeInfo = [(id<SCIOCTypeInspectable>)parent collectionMemberTypeInfo];
            if (typeInfo) {
                id type = typeInfo[propName];
                if (object_isClass(type)) {
                    _memberTypeInfo = [[SCPropertyInfo alloc] initAsWriteableWithClass:(Class)type];
                }
                else if (type == NSClassFromString(@"Protocol")) {
                    _memberTypeInfo = [[SCPropertyInfo alloc] initAsWriteableWithProtocol:(Protocol *)type];
                }
            }
        }
        if (!_memberTypeInfo) {
            // Can't resolve any class for the collection's members, use an all-type info.
            _memberTypeInfo = [[SCPropertyInfo alloc] initAsWriteable];
        }
    }
    return self;
}

- (SCPropertyInfo *)infoForProperty:(NSString *)propName {
    return _memberTypeInfo;
}

@end

@implementation SCContainerTypeInfo

- (id)initWithContainer:(id<SCContainer>)container {
    self = [super init];
    if (self) {
        // Look up the container object's type information using the standard lookup, before
        // copying the property info to this instance. This is to ensure that type info lookup
        // goes through the standard cache mechanism.
        SCTypeInfo *typeInfo = [SCTypeInfo typeInfoForObject:container];
        self->_properties = typeInfo->_properties;
    }
    return self;
}

- (SCPropertyInfo *)infoForProperty:(NSString *)propName {
    SCPropertyInfo *propInfo = [super infoForProperty:propName];
    // If the property name doesn't correspond to a declared property of the container class then
    // return a generic property info. This is necessary to allow arbitrary named objects to be
    // created and configured on the container.
    if (!propInfo) {
        // Note that this is a non-writeable property.
        propInfo = [SCPropertyInfo new];
    }
    return propInfo;
}

@end
