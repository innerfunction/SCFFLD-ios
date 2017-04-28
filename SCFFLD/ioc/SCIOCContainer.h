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
#import "SCContainer.h"
#import "SCTypeInfo.h"
#import "SCPendingNamed.h"
#import "SCLogger.h"

@class SCObjectConfigurer;

/**
 * A container for named objects and services.
 * Acts as an object factory and IOC container. Objects built using this class are
 * instantiated and configured using an object definition read from a JSON configuration.
 * The object's properties may be configured using other built objects, or using references
 * to named objects contained by the container.
 */
@interface SCIOCContainer : NSObject <SCContainer> {
    /// A map of named objects.
    NSMutableDictionary *_named;
    /// A list of contained services.
    NSMutableArray *_services;
    /// Map of standard type names onto platform specific class names.
    id<SCConfiguration> _types;
    /// The container's configuration.
    id<SCConfiguration> _containerConfig;
    /// Type info for the container's properties - allows type inferring of named properties.
    SCTypeInfo *_propertyTypeInfo;
    /**
     * A map of pending object names (i.e. objects in the process of being configured) mapped onto
     * a list of pending value references (i.e. property value references to other pending objects,
     * which are caused by circular dependency cycles and which can't be fully resolved until the
     * referenced value has been fully built).
     * Used to detect dependency cycles when building the named object graph.
     * @see <SCPendingNamed>
     */
    NSMutableDictionary *_pendingNames;
    /**
     * A map of pending property value reference counts, keyed by the property's parent object. Used to
     * manage deferred calls to the <SCIOCConfigurationAware> [afterIOCConfiguration:] method.
     */
    NSMutableDictionary *_pendingValueRefCounts;
    /**
     * A map of pending value object configurations. These are the configurations for the parent
     * objects of pending property values. These are needed for deferred calls to the
     * <SCIOCConfigurationAware> [afterIOCConfiguration] method.
     */
    NSMutableDictionary *_pendingValueObjectConfigs;
    /// Flag indicating whether the container and all its services are running.
    BOOL _running;
    /// An object configurer for the container.
    SCObjectConfigurer *_containerConfigurer;
    /// The container logger.
    SCLogger *_logger;
}

/** Perform standard post-instantiation operations on a new object instance. */
- (void)doPostInstantiation:(id)object;
/** Perform standard post-configuration operations on a new object instance. */
- (void)doPostConfiguration:(id)object;

/** Increment the number of pending value refs for an object. */
- (void)incPendingValueRefCountForPendingObject:(SCPendingNamed *)pending;
/** Test whether an object has pending value references. */
- (BOOL)hasPendingValueRefsForObjectKey:(id)objectKey;
/**
 * Record the configuration for an object with pending value references.
 * Needed to ensure the the [SCIOCConfigurationAware afterConfiguration:] method is called correctly.
 */
- (void)recordPendingValueObjectConfiguration:(id<SCConfiguration>)configuration forObjectKey:(id)objectKey;

/**
 * Register an IOC configuration proxy class for properties of a specific class.
 * The proxy will be used for all subclasses of the property class also, unless a different proxy is registered
 * for a specific subclass. No proxy will be used for a specific subclass if a nil proxy class name is registered.
 */
+ (void)registerConfigurationProxyClass:(__unsafe_unretained Class)proxyClass forClassName:(NSString *)className;

/**
 * Check whether a configuration proxy is registered for an object's class, and if so then return an instance of
 * the proxy initialized with the object, otherwise return the object unchanged.
 */
+ (id)applyConfigurationProxyWrapper:(id)object;

@end

