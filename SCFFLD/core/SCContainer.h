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
//  Created by Julian Goacher on 22/04/2015.
//  Copyright (c) 2015 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCConfiguration.h"
#import "SCMessageRouter.h"
#import "SCMessageReceiver.h"
#import "SCService.h"
#import "SCLogger.h"

/**
 * A protocol for containers of named objects and services.
 * Acts as an object factory and IOC container. Objects built using this class are
 * instantiated and configured using an object definition read from a JSON configuration.
 * The object's properties may be configured using other built objects, or using references
 * to named objects contained by the container.
 */
@protocol SCContainer <SCConfigurationData, SCService, SCMessageReceiver, SCMessageRouter>

/// The parent container of a nested container.
@property (nonatomic, weak) id<SCContainer> parentContainer;
/**
 * A list of names which should be built before the rest of the container's configuration is processed.
 * Names should be listed in priority order.
 */
@property (nonatomic, strong) NSArray *priorityNames;
/// The container's URI handler. This is resolved from the container's configuration.
@property (nonatomic, strong) id<SCURIHandler> uriHandler;

/**
 * Get a named component.
 * In a nested container, if _name_ isn't mapped to a component in the current container then this method
 * will call _getNamed:_ on the parent container. This creates a natural scoping rule for names, where global
 * names can be defined in the top-most container (e.g. the app container) with more local names being
 * defined in nested containers. Nested contains can in turn override global names by providing their own
 * mappings for such names.
 */
- (id)getNamed:(NSString *)name;
/** Add additional type name mappings to the type map. */
- (void)addTypes:(id)types;

/// Build an object from the provided configuration data.
- (id)buildObjectWithData:(id)data;
/// Build an object from the provided configuration data and parameters.
- (id)buildObjectWithData:(id)data parameters:(NSDictionary *)params;
/// Build an object from the provided configuration data and parameters, and with the specified object identifier.
- (id)buildObjectWithData:(id)data parameters:(NSDictionary *)params identifier:(NSString *)identifier;
/**
 * Instantiate and configure an object using the specified configuration.
 * @param configuration A configuration describing the object to build.
 * @param identifier    An identifier (e.g. the configuration's key path) used identify the object in logs.
 * @return The instantiated and fully configured object.
 */
- (id)buildObjectWithConfiguration:(id<SCConfiguration>)configuration identifier:(NSString *)identifier;
/**
 * Instantiate an object from the specified configuration.
 * @param configuration A configuration with instantiation hints that can be used to create an object instance.
 * @param identifier    An identifier (e.g. the configuration's key path) used identify the object in logs.
 * @return A newly instantiated object.
 */
- (id)instantiateObjectWithConfiguration:(id<SCConfiguration>)configuration identifier:(NSString *)identifier;
/**
 * Instantiate an instance of the named type. Looks for a classname in the set of registered types, and then
 * returns the result of calling [newInstanceForClassName: withConfiguration:].
 */
- (id)newInstanceForTypeName:(NSString *)typeName withConfiguration:(id<SCConfiguration>)configuration;
/**
 * Instantiate an instance of the named class.
 * @return Returns a new instance of the class, unless a configuration proxy is registered for the class name
 * in which case a new instance of the proxy class is returned.
 */
- (id)newInstanceForClassName:(NSString *)className withConfiguration:(id<SCConfiguration>)configuration;
/**
 * Configure an object using the specified configuration.
 * @param object        The object to configure.
 * @param configuration The object's configuration.
 * @param identifier    An identifier (e.g. the configuration's key path) used identify the object in logs.
 */
- (void)configureObject:(id)object withConfiguration:(id<SCConfiguration>)configuration identifier:(NSString *)identifier;
/**
 * Configure the container and its contents using the specified configuration.
 * The set of 'named' components is instantiated from the top-level configuration properties. In addition, if
 * any named property has the same name as one of the container's properties, then the container property is set
 * to the value of the named property. Type inference will be attempted for named container properties without
 * explicitly configured types. The mapping of named container properties is primarily useful in container subclasses,
 * and can be used to define functional modules as configurable containers.
 */
- (void)configureWith:(id<SCConfiguration>)configuration;
/** Configure the container with the specified data. */
- (void)configureWithData:(id)configData;

/** Instantiate and configure a named object. */
- (id)buildNamedObject:(NSString *)name;


@end

