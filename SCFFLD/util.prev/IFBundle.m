//
//  SCFFLD
//
//  Created by Julian Goacher on 21/03/2017.
//  Copyright © 2017 InnerFunction. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IFBundle.h"
//#import "UINibLoading.h"

#define FileExists(path)    ([[NSFileManager defaultManager] fileExistsAtPath:path])

@interface IFBundle ()

- (NSString *)_pathForResource:(NSString *)name withExtension:(NSString *)ext subdirectory:(NSString *)subpath;
- (void)_localizeTextViewChildren:(UIView *)view;

@end

@implementation IFBundle

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"

- (id)initWithPath:(NSString *)path {
    self = [super init];
    if (self ) {
        bundlePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:path];
        NSLog(@"%@",bundlePath);
        bundle = [NSBundle mainBundle];
    }
    return self;
}

#pragma clang diagnostic pop


- (NSURL *)bundleURL {
    return bundle.bundleURL;
}

- (NSURL *)resourceURL {
    return bundle.resourceURL;
}

- (NSURL *)executableURL {
    return bundle.executableURL;
}

- (NSURL *)privateFrameworksURL {
    return bundle.privateFrameworksURL;
}

- (NSURL *)sharedFrameworksURL {
    return bundle.sharedFrameworksURL;
}

- (NSURL *)sharedSupportURL {
    return bundle.sharedSupportURL;
}

- (NSURL *)builtInPlugInsURL {
    return bundle.builtInPlugInsURL;
}

- (NSURL *)appStoreReceiptURL {
    return bundle.appStoreReceiptURL;
}

- (NSString *)bundlePath {
    return bundle.bundlePath;
}

- (NSString *)resourcePath {
    return bundle.resourcePath;
}

- (NSString *)executablePath {
    return bundle.executablePath;
}

- (NSString *)pathForAuxiliaryExecutable:(NSString *)executableName {
    return [bundle pathForAuxiliaryExecutable:executableName];
}

- (NSString *)privateFrameworksPath {
    return bundle.sharedFrameworksPath;
}

- (NSString *)sharedFrameworksPath {
    return bundle.sharedFrameworksPath;
}

- (NSString *)sharedSupportPath {
    return bundle.sharedSupportPath;
}

- (NSString *)builtInPlugInsPath {
    return bundle.builtInPlugInsPath;
}

- (NSString *)bundleIdentifier {
    return bundle.bundleIdentifier;
}

- (NSDictionary<NSString *, id> *)infoDictionary {
    return bundle.infoDictionary;
}

- (NSDictionary<NSString *, id> *)localizedInfoDictionary {
    return bundle.localizedInfoDictionary;
}

- (nullable id)objectForInfoDictionaryKey:(NSString *)key {
    return [bundle objectForInfoDictionaryKey:key];
}

- (nullable Class)classNamed:(NSString *)className {
    return [bundle classNamed:className];
}

- (Class)principalClass {
    return bundle.principalClass;
}

- (NSArray<NSString *> *)preferredLocalizations {
    return bundle.preferredLocalizations;
}

- (NSArray<NSString *> *)localizations {
    return bundle.localizations;
}

- (NSString *)developmentLocalization {
    return bundle.developmentLocalization;
}

- (NSString *)_pathForResource:(NSString *)name withExtension:(NSString *)ext subdirectory:(NSString *)subpath {
    NSString *path = bundlePath;
    if (subpath) {
        path = [path stringByAppendingPathComponent:subpath];
    }
    path = [path stringByAppendingPathComponent:name];
    if (ext) {
        path = [path stringByAppendingPathExtension:ext];
    }
    return path;
}

- (void)_localizeTextViewChildren:(UIView *)view {
    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        NSString *text = [self localizedStringForKey:label.text value:nil table:nil];
        if (text) {
            label.text = text;
        }
    }
    for (UIView *subview in view.subviews) {
        [self _localizeTextViewChildren:subview];
    }
}

- (nullable NSURL *)URLForResource:(nullable NSString *)name withExtension:(nullable NSString *)ext {
    NSLog(@"* URLForResource:%@ withExtension:%@", name, ext );
    NSString *path = [self _pathForResource:name withExtension:ext subdirectory:nil];
    if (FileExists(path)) {
        return [NSURL fileURLWithPath:path];
    }
    return [[NSBundle mainBundle] URLForResource:name withExtension:ext];
}

- (nullable NSURL *)URLForResource:(nullable NSString *)name withExtension:(nullable NSString *)ext subdirectory:(nullable NSString *)subpath {
    NSLog(@"* URLForResource:%@ withExtension:%@ subdirectory:%@", name, ext, subpath );
    NSString *path = [self _pathForResource:name withExtension:ext subdirectory:subpath];
    if (FileExists(path)) {
        return [NSURL fileURLWithPath:path];
    }
    return [[NSBundle mainBundle] URLForResource:name withExtension:ext subdirectory:subpath];
}

- (nullable NSURL *)URLForResource:(nullable NSString *)name withExtension:(nullable NSString *)ext subdirectory:(nullable NSString *)subpath localization:(nullable NSString *)localizationName {
    NSLog(@"* URLForResource:%@ withExtension:%@ subdirectory:%@ localization:%@", name, ext, subpath, localizationName );
    return [[NSBundle mainBundle] URLForResource:name withExtension:ext subdirectory:subpath localization:localizationName];
}

- (nullable NSArray<NSURL *> *)URLsForResourcesWithExtension:(nullable NSString *)ext subdirectory:(nullable NSString *)subpath {
    NSLog(@"* URLsForResourcesWithExtension:%@ subdirectory:%@", ext, subpath );
    return [[NSBundle mainBundle] URLsForResourcesWithExtension:ext subdirectory:subpath];
}

- (nullable NSArray<NSURL *> *)URLsForResourcesWithExtension:(nullable NSString *)ext subdirectory:(nullable NSString *)subpath localization:(nullable NSString *)localizationName {
    NSLog(@"* URLsForResourcesWithExtension:%@ subdirectory:%@ localization:%@", ext, subpath, localizationName );
    return [[NSBundle mainBundle] URLsForResourcesWithExtension:ext subdirectory:subpath localization:localizationName];
}

- (nullable NSString *)pathForResource:(nullable NSString *)name ofType:(nullable NSString *)ext {
    NSLog(@"* pathForResource:%@ ofType:%@", name, ext );
    NSString *path = [self _pathForResource:name withExtension:ext subdirectory:nil];
    if (FileExists(path)) {
        return path;
    }
    return [[NSBundle mainBundle] pathForResource:name ofType:ext];
}

- (nullable NSString *)pathForResource:(nullable NSString *)name ofType:(nullable NSString *)ext inDirectory:(nullable NSString *)subpath {
    NSLog(@"* pathForResource:%@ ofType:%@ inDirectory:%@", name, ext, subpath );
    NSString *path = [self _pathForResource:name withExtension:ext subdirectory:subpath];
    if (FileExists(path)) {
        return path;
    }
    return [[NSBundle mainBundle] pathForResource:name ofType:ext inDirectory:subpath];
}

- (nullable NSString *)pathForResource:(nullable NSString *)name ofType:(nullable NSString *)ext inDirectory:(nullable NSString *)subpath forLocalization:(nullable NSString *)localizationName {
    NSLog(@"* pathForResource:%@ ofType:%@ inDirectory:%@ forLocalization:%@", name, ext, subpath, localizationName );
    return [[NSBundle mainBundle] pathForResource:name ofType:ext inDirectory:subpath forLocalization:localizationName];
}

- (NSArray<NSString *> *)pathsForResourcesOfType:(nullable NSString *)ext inDirectory:(nullable NSString *)subpath {
    NSLog(@"* pathsForResourcesOfType:%@ inDirectory:%@", ext, subpath );
    return [[NSBundle mainBundle] pathsForResourcesOfType:ext inDirectory:subpath];
}

- (NSArray<NSString *> *)pathsForResourcesOfType:(nullable NSString *)ext inDirectory:(nullable NSString *)subpath forLocalization:(nullable NSString *)localizationName {
    NSLog(@"* pathsForResourcesOfType:%@ inDirectory:%@ forLocalization:%@", ext, subpath, localizationName );
    return [[NSBundle mainBundle] pathsForResourcesOfType:ext inDirectory:subpath forLocalization:localizationName];
}

- (NSString *)localizedStringForKey:(NSString *)key value:(nullable NSString *)value table:(nullable NSString *)tableName {
    NSLog(@"* localizedStringForKey:%@ value:%@ table:%@", key, value, tableName );
    return @"LOCALIZED TEXT HERE";
//    return [[NSBundle mainBundle] localizedStringForKey:key value:value table:tableName];
}

- (NSArray *)loadNibNamed:(NSString *)name owner:(id)owner options:(NSDictionary *)options {
    NSArray *result = [super loadNibNamed:name owner:owner options:options];
    for (UIView *view in result) {
        [self _localizeTextViewChildren:view];
    }
    return result;
}

@end
