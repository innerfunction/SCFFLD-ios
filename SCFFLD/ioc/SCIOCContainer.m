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

#import "SCIOCContainer.h"
#import "SCConfigurable.h"
#import "SCIOCTypeInspectable.h"
#import "SCIOCConfigurationInitable.h"
#import "SCIOCContainerAware.h"
#import "SCIOCConfigurationAware.h"
#import "SCIOCSingleton.h"
#import "SCIOCObjectAware.h"
#import "SCIOCObjectFactory.h"
#import "SCIOCProxy.h"
#import "SCIOCProxyObject.h"
#import "SCIOCConfiguration.h"
#import "SCObjectConfigurer.h"
#import "SCPostScheme.h"
#import "SCTypeConversions.h"

/** Entry for a configurable proxy in the proxy lookup table. */
@interface SCIOCProxyLookupEntry : NSObject {
    __unsafe_unretained Class _class;
}

- (id)initWithClass:(__unsafe_unretained Class)class;

/** Use the entry to instantiate a new proxy instance with no in-place value. */
- (id<SCIOCProxy>)instantiateProxy;

/** Use the entry to instantiate a new proxy instance with an in-place value. */
- (id<SCIOCProxy>)instantiateProxyWithValue:(id)value;

@end

@interface SCIOCContainer ()

/** Lookup a configuration proxy for an object instance. */
+ (SCIOCProxyLookupEntry *)lookupConfigurationProxyForObject:(id)object;

/** Lookup a configuration proxy for a named class. */
+ (SCIOCProxyLookupEntry *)lookupConfigurationProxyForClassName:(NSString *)className;

/** Lookup a configuration proxy for a class. */
+ (SCIOCProxyLookupEntry *)lookupConfigurationProxyForClass:(__unsafe_unretained Class)class className:(NSString *)className;

@end

@implementation SCIOCContainer

@synthesize parentContainer=_parentContainer,
            priorityNames=_priorityNames,
            uriHandler=_uriHandler;

- (id)init {
    self = [super init];
    if (self) {
        _named = [NSMutableDictionary new];
        _services = [NSMutableArray new];
        _types = [SCIOCConfiguration emptyConfiguration];
        _running = NO;
        _propertyTypeInfo = [SCTypeInfo typeInfoForObject:self];
        _pendingNames = [NSMutableDictionary new];
        _pendingValueRefCounts = [NSMutableDictionary new];
        _pendingValueObjectConfigs = [NSMutableDictionary new];
        _containerConfigurer = [[SCObjectConfigurer alloc] initWithContainer:self];
        _logger = [[SCLogger alloc] initWithTag:@"SCContainer"];
    }
    return self;
}

- (void)addTypes:(id)types {
    if (types) {
        id<SCConfiguration> typeConfig;
        if ([types conformsToProtocol:@protocol(SCConfiguration)]) {
            typeConfig = (id<SCConfiguration>)types;
        }
        else {
            typeConfig = [[SCIOCConfiguration alloc] initWithData:types];
        }
        _types = [_types mixinConfiguration:typeConfig];
    }
}

- (id)buildObjectWithData:(id)data {
    return [self buildObjectWithData:data parameters:nil];
}

- (id)buildObjectWithData:(id)data parameters:(NSDictionary *)params {
    return [self buildObjectWithData:data parameters:params identifier:[data description]];
}

- (id)buildObjectWithData:(id)data parameters:(NSDictionary *)params identifier:(NSString *)identifier {
    id<SCConfiguration> config;
    if ([data conformsToProtocol:@protocol(SCConfiguration)]) {
        config = (id<SCConfiguration>)data;
    }
    else {
        config = [[SCIOCConfiguration alloc] initWithData:data parent:_containerConfig];
    }
    config = [config normalize];
    if (params) {
        config = [config extendWithParameters:params];
    }
    return [self buildObjectWithConfiguration:config identifier:identifier];
}

// Build a new object from its configuration by instantiating a new instance and configuring it.
- (id)buildObjectWithConfiguration:(id<SCConfiguration>)configuration identifier:(NSString *)identifier {
    id object = nil;
    if ([configuration hasValue:@"-factory"]) {
        // The configuration specifies an object factory, so resolve the factory object and attempt
        // using it to instantiate the object.
        id factory = [configuration getValue:@"-factory"];
        if ([factory conformsToProtocol:@protocol(SCIOCObjectFactory)]) {
            object = [(id<SCIOCObjectFactory>)factory buildObjectWithConfiguration:configuration inContainer:self identifier:identifier];
            [self doPostInstantiation:object];
            [self doPostConfiguration:object];
        }
        else {
            [_logger error:@"Building %@, invalid factory class '%@'", identifier, [factory class]];
        }
    }
    else {
        // Try instantiating object from type or class info.
        object = [self instantiateObjectWithConfiguration:configuration identifier:identifier];
        if (object) {
            // Configure the resolved object.
            [self configureObject:object withConfiguration:configuration identifier:identifier];
        }
    }
    return object;
}

// Use class or type info in a cofiguration to instantiate a new object.
- (id)instantiateObjectWithConfiguration:(id<SCConfiguration>)configuration identifier:(NSString *)identifier {
    id object = nil;
    NSString *className = [configuration getValueAsString:@"-ios-class"];
    if (!className) {
        className = [configuration getValueAsString:@"-ios:class"];
    }
    if (!className) {
        className = [configuration getValueAsString:@"-class"];
    }
    if (!className) {
        NSString *type = [configuration getValueAsString:@"-type"];
        if (type) {
            className = [_types getValueAsString:type];
            if (!className) {
                [_logger error:@"Instantiating %@, no class name found for type %@", identifier, type];
            }
        }
        else {
            // This can be OK in some circumstances.
            //[_logger error:@"Instantiating %@, Component configuration missing -type or -ios-class property", identifier];
        }
    }
    if (className) {
        object = [self newInstanceForClassName:className withConfiguration:configuration];
    }
    return object;
}

// Instantiate a new object from type name info.
- (id)newInstanceForTypeName:(NSString *)typeName withConfiguration:(id<SCConfiguration>)configuration {
    NSString *className = [_types getValueAsString:typeName];
    if (!className) {
        [_logger warn:@"newInstanceForTypeName, no class name found for type %@", typeName];
        return nil;
    }
    return [self newInstanceForClassName:className withConfiguration:configuration];
}

// Instantiate a new object from classname info.
- (id)newInstanceForClassName:(NSString *)className withConfiguration:(id<SCConfiguration>)configuration {
    // Attempt to resolve the class from its name - this is done first in case the class declares its
    // own configuration proxy (e.g. in a static initializer).
    Class class = NSClassFromString(className);
    if (class == nil) {
        [_logger error:@"Class not found %@", className];
        return nil;
    }
    id instance;
    // If config proxy available for classname then instantiate proxy instead of new instance.
    SCIOCProxyLookupEntry *proxyEntry = [SCIOCContainer lookupConfigurationProxyForClassName:className];
    if (proxyEntry) {
        instance = [proxyEntry instantiateProxy];
    }
    else {
        // Otherwise continue with class instantiation.
        // Check for singleton classes.
        if ([class conformsToProtocol:@protocol(SCIOCSingleton)]) {
            // Return the class' singleton instance.
            instance = [(id<SCIOCSingleton>)class iocSingleton];
        }
        else {
            // Allocate and instantiate a new class instance.
            instance = [class alloc];
            if ([instance conformsToProtocol:@protocol(SCIOCConfigurationInitable)]) {
                instance = [(id<SCIOCConfigurationInitable>)instance initWithConfiguration:configuration];
            }
            else {
                instance = [instance init];
            }
        }
    }
    [self doPostInstantiation:instance];
    return instance;
}

// Configure an object instance.
- (void)configureObject:(id)object withConfiguration:(id<SCConfiguration>)configuration identifier:(NSString *)identifier {
    [_containerConfigurer configureObject:object
                        withConfiguration:configuration
                            keyPathPrefix:identifier];
}

// Configure the container with the specified configuration.
// The container performs implicit dependency ordering. This means that if an object A has a dependency
// on another object B, then B will be built (instantiated & configured) before A. This will work for an
// arbitrary length dependency chain (e.g. A -> B -> C -> etc.)
// Implicit dependency ordering relies on the fact that dependencies like this can only be specified using
// the named: URI scheme, which uses the container's getNamed: method to resolve named objects.
// The configuration process works as follows:
// * This method iterates over each named object configuration and builds each object in turn.
// * If any named object has a dependency on another named object then this will be resolved via the named:
//   URI scheme and the container's getNamed: method.
// * In the getNamed: method, if a name isn't found but a configuration exists then the container will
//   attempt to build and return the named object. This means that in effect, building of an object is
//   temporarily suspended whilst building of its dependency is prioritized. This process will recurse
//   until the full dependency chain is resolved.
// * The container maintains a map of names being built. This allows the container to detect dependency
//   cycles and so avoid infinite regression. Dependency cycles are resolved, but the final object in a
//   cycle won't be fully configured when injected into the dependent.
- (void)configureWith:(id<SCConfiguration>)configuration {
    _containerConfig = configuration;
    self.uriHandler = configuration.uriHandler;
    
    // Build the priority names first.
    for (NSString *name in _priorityNames) {
        [self buildNamedObject:name];
    }

    // Iterate over named object configs and build each object.
    NSArray *names = [_containerConfig getValueNames];
    for (NSString *name in names) {
        // Build the object only if it has not already been built and added to _named_.
        // (Objects which are dependencies of other objects may be configured via getNamed:
        // before this loop has iterated around to them; or core names).
        if (_named[name] == nil) {
            [self buildNamedObject:name];
        }
    }
}

// Build a named object from the available configuration and property type info.
- (id)buildNamedObject:(NSString *)name {
    // Track that we're about to build this name.
    _pendingNames[name] = @[];
    id object = [_containerConfigurer configureNamed:name withConfiguration:_containerConfig];
    if (object != nil) {
        // Map the named object.
        _named[name] = object;
    }
    // Object is configured, notify any pending named references
    NSArray *pendings = _pendingNames[name];
    for (SCPendingNamed *pending in pendings) {
        if ([pending hasWaitingConfigurer]) {
            [pending completeWithValue:object];
            // Decrement the number of pending value refs for the property object.
            NSInteger refCount = [(NSNumber *)_pendingValueRefCounts[pending.objectKey] integerValue] - 1;
            if (refCount > 0) {
                _pendingValueRefCounts[pending.objectKey] = [NSNumber numberWithInteger:refCount];
            }
            else {
                [_pendingValueRefCounts removeObjectForKey:pending.objectKey];
                id completed = pending.object;
                // The property object is now fully configured, invoke its afterConfiguration: method if it
                // implements SCIOCConfigurationAware protocol.
                if ([completed conformsToProtocol:@protocol(SCIOCConfigurationAware)]) {
                    id<SCConfiguration> objConfig = _pendingValueObjectConfigs[pending.objectKey];
                    [(id<SCIOCConfigurationAware>)completed afterIOCConfiguration:objConfig];
                    [_pendingValueObjectConfigs removeObjectForKey:pending.objectKey];
                }
            }
        }
    }
    // Finished building the current name, remove from list.
    [_pendingNames removeObjectForKey:name];
    return object;
}

// Get a named object. Will attempt building the object if necessary.
- (id)getNamed:(NSString *)name {
    // Allow the container to be referenced as named:-container
    if ([@"-container" isEqualToString:name]) {
        return self;
    }
    id object = _named[name];
    // If named object not found then consider whether to try building it.
    if (object == nil) {
        // Check for a dependency cycle. If the requested name exists in _pendingNames_ then the named object is currently
        // being configured.
        NSArray *pending = _pendingNames[name];
        if (pending != nil) {
            // TODO: Add option to throw exception here, instead of logging the problem.
            [_logger info:@"IDO: Named dependency cycle detected, creating pending entry for %@...", name];
            // Create a placeholder object and record in the list of placeholders waiting for the named configuration to complete.
            // Note that the placeholder is returned in place of the named - code above detects the placeholder and ensures that
            // the correct value is resolved instead.
            object = [SCPendingNamed new];
            pending = [pending arrayByAddingObject:object];
            _pendingNames[name] = pending;
        }
        else if ([_containerConfig hasValue:name]) {
            // The container config contains a configuration for the wanted name, but _named_ doesn't contain
            // any reference so therefore it's likely that the object hasn't been built yet; try building it now.
            object = [self buildNamedObject:name];
        }
    }
    // If the required name can't be resolved by this container, and it this container is a nested
    // container (and so has a parent) then ask the parent container to resolve the name.
    if (object == nil && _parentContainer) {
        object = [_parentContainer getNamed:name];
    }
    return object;
}

- (void)configureWithData:(id)configData {
    id<SCConfiguration> configuration = [[SCIOCConfiguration alloc] initWithData:configData];
    [self configureWith:configuration];
}

- (void)doPostInstantiation:(id)object {
    // If the new instance is container aware then pass reference to this container.
    if ([object conformsToProtocol:@protocol(SCIOCContainerAware)]) {
        ((id<SCIOCContainerAware>)object).iocContainer = self;
    }
    // If the new instance is a nested container then set its parent reference.
    if ([object conformsToProtocol:@protocol(SCContainer)]) {
        ((id<SCContainer>)object).parentContainer = self;
    }
}

- (void)doPostConfiguration:(id)object {
    // Check for new services.
    if ([object conformsToProtocol:@protocol(SCService)]) {
        if (_running) {
            // If running then start the service now that it is fully configured.
            [(id<SCService>)object startService];
        }
        else {
            // Otherwise add to the list of services and start later.
            [_services addObject:(id<SCService>)object];
        }
    }
}

- (void)incPendingValueRefCountForPendingObject:(SCPendingNamed *)pending {
    NSNumber *refCount = _pendingValueRefCounts[pending.objectKey];
    if (refCount) {
        _pendingValueRefCounts[pending.objectKey] = [NSNumber numberWithInteger:([refCount integerValue] + 1)];
    }
    else {
        _pendingValueRefCounts[pending.objectKey] = @1;
    }
}

- (BOOL)hasPendingValueRefsForObjectKey:(id)objectKey {
    return (_pendingValueRefCounts[objectKey] != nil);
}

- (void)recordPendingValueObjectConfiguration:(id<SCConfiguration>)configuration forObjectKey:(id)objectKey {
    _pendingValueObjectConfigs[objectKey] = configuration;
}

#pragma mark - SCService

- (void)startService {
    _running = YES;
    for (id<SCService> service in _services) {
        @try {
            [service startService];
        }
        @catch (NSException *exception) {
            [_logger error:@"Error starting service %@: %@", [service class], exception];
        }
    }
}

- (void)stopService {
    SEL stopService = @selector(stopService);
    for (id<SCService> service in _services) {
        @try {
            if ([service respondsToSelector:stopService]) {
                [service stopService];
            }
        }
        @catch (NSException *exception) {
            [_logger error:@"Error stopping service %@: %@", [service class], exception];
        }
    }
    _running = NO;
}

#pragma mark - SCConfigurationData

// TODO: Review the need for this protocol
- (id)getValue:(NSString *)keyPath asRepresentation:(NSString *)representation {
    id value = [self getNamed:keyPath];
    if (value && ![@"bare" isEqualToString:representation]) {
        value = [SCTypeConversions value:value asRepresentation:representation];
    }
    return value;
}

#pragma mark - SCMessageRouter

- (BOOL)routeMessage:(SCMessage *)message sender:(id)sender {
    BOOL routed = NO;
    if ([message hasEmptyTarget]) {
        // Message is targeted at this object.
        routed = [self receiveMessage:message sender:sender];
    }
    else {
        // Look-up the message target in named objects.
        NSString *targetHead = [message targetHead];
        id target = _named[targetHead];
        if (target) {
            message = [message popTargetHead];
            // If we have the intended target, and the target is a message handler, then let it handle the message.
            if ([message hasEmptyTarget]) {
                if ([target conformsToProtocol:@protocol(SCMessageReceiver)]) {
                    routed = [(id<SCMessageReceiver>)target receiveMessage:message sender:sender];
                }
            }
            else if ([target conformsToProtocol:@protocol(SCMessageRouter)]) {
                // Let the current target dispatch the message to its intended target.
                routed = [(id<SCMessageRouter>)target routeMessage:message sender:sender];
            }
        }
    }
    return routed;
}

#pragma mark - SCMessageReceiver

- (BOOL)receiveMessage:(SCMessage *)message sender:(id)sender {
    return NO;
}

#pragma mark - Static methods

// May of configuration proxies keyed by class name. Classes without a registered proxy get an NSNull entry.
static NSMutableDictionary *SCIOCContainer_proxies;

+ (void)initialize {
    if (!SCIOCContainer_proxies) {
        SCIOCContainer_proxies = [NSMutableDictionary new];
        NSDictionary *registeredProxyClasses = [SCIOCProxyObject registeredProxyClasses];
        for (NSString *className in registeredProxyClasses) {
            NSValue *value = (NSValue *)registeredProxyClasses[className];
            __unsafe_unretained Class proxyClass = (Class)[value nonretainedObjectValue];
            SCIOCProxyLookupEntry *proxyEntry = [[SCIOCProxyLookupEntry alloc] initWithClass:proxyClass];
            SCIOCContainer_proxies[className] = proxyEntry;
        }
    }
}

+ (void)registerConfigurationProxyClass:(__unsafe_unretained Class)proxyClass forClassName:(NSString *)className {
    if (!proxyClass) {
        SCIOCContainer_proxies[className] = [NSNull null];
    }
    else {
        SCIOCProxyLookupEntry *proxyEntry = [[SCIOCProxyLookupEntry alloc] initWithClass:proxyClass];
        SCIOCContainer_proxies[className] = proxyEntry;
    }
}

+ (SCIOCProxyLookupEntry *)lookupConfigurationProxyForObject:(id)object {
    __unsafe_unretained Class class = [object class];
    NSString *className = NSStringFromClass(class);
    return [SCIOCContainer lookupConfigurationProxyForClass:class className:className];
}

+ (SCIOCProxyLookupEntry *)lookupConfigurationProxyForClassName:(NSString *)className {
    __unsafe_unretained Class class = NSClassFromString(className);
    return [SCIOCContainer lookupConfigurationProxyForClass:class className:className];
}

+ (SCIOCProxyLookupEntry *)lookupConfigurationProxyForClass:(__unsafe_unretained Class)class className:(NSString *)className {
    // First check for an entry under the current object's specific class name.
    id proxyEntry = SCIOCContainer_proxies[className];
    if (proxyEntry != nil) {
        // NSNull at this stage indicates no proxy available for the specific object class.
        return proxyEntry == [NSNull null] ? nil : (SCIOCProxyLookupEntry *)proxyEntry;
    }
    // No entry found for the specific class, search for the closest superclass proxy.
    NSString *specificClassName = className;
    class = [class superclass];
    while (class) {
        className = NSStringFromClass(class);
        proxyEntry = SCIOCContainer_proxies[className];
        if (proxyEntry) {
            // Proxy found, record the same proxy for the specific class and return the result.
            SCIOCContainer_proxies[specificClassName] = proxyEntry;
            return proxyEntry == [NSNull null] ? nil : (SCIOCProxyLookupEntry *)proxyEntry;
        }
        // Nothing found yet, continue to the next superclass.
        class = [class superclass];
    }
    // If we get to here then there is no registered proxy available for the object's class or any of its
    // superclasses; register an NSNull in the dictionary so that future lookups can complete quicker.
    SCIOCContainer_proxies[specificClassName] = [NSNull null];
    return nil;
}

+ (id)applyConfigurationProxyWrapper:(id)object {
    if (object != nil) {
        SCIOCProxyLookupEntry *proxyEntry = [SCIOCContainer lookupConfigurationProxyForObject:object];
        if (proxyEntry) {
            object = [proxyEntry instantiateProxyWithValue:object];
        }
    }
    return object;
}

@end

#pragma mark - SCIOCProxyLookupEntry

@implementation SCIOCProxyLookupEntry

- (id)initWithClass:(__unsafe_unretained Class)class {
    self = [super init];
    if (self) {
        _class = class;
    }
    return self;
}

- (id<SCIOCProxy>)instantiateProxy {
    return (id<SCIOCProxy>)[_class new];
}

- (id<SCIOCProxy>)instantiateProxyWithValue:(id)value {
    id<SCIOCProxy> instance = (id<SCIOCProxy>)[_class alloc];
    return [instance initWithValue:value];
}

@end
