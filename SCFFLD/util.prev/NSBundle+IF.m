//
//  NSBundle+NSBundle_IF.m
//  SCFFLD
//
//  Created by Julian Goacher on 21/03/2017.
//  Copyright © 2017 InnerFunction. All rights reserved.
//

#import "NSBundle+IF.h"
#import <objc/runtime.h>

@implementation NSBundle (IF)
/*
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        // Taken from http://nshipster.com/method-swizzling/
        
        Class class = [self class];

        SEL originals[] = {
            @selector(URLForResource:withExtension:),
            @selector(URLForResource:withExtension:subdirectory:),
            @selector(URLForResource:withExtension:subdirectory:localization:),
            @selector(URLsForResourcesWithExtension:subdirectory:),
            @selector(URLsForResourcesWithExtension:subdirectory:localization:),
            @selector(pathForResource:ofType:),
            @selector(pathForResource:ofType:inDirectory:),
            @selector(pathForResource:ofType:inDirectory:forLocalization:),
            @selector(pathsForResourcesOfType:inDirectory:),
            @selector(pathsForResourcesOfType:inDirectory:forLocalization:),
            @selector(localizedStringForKey:value:table:)
        };

        SEL replacements[] = {
            @selector(if_URLForResource:withExtension:),
            @selector(if_URLForResource:withExtension:subdirectory:),
            @selector(if_URLForResource:withExtension:subdirectory:localization:),
            @selector(if_URLsForResourcesWithExtension:subdirectory:),
            @selector(if_URLsForResourcesWithExtension:subdirectory:localization:),
            @selector(if_pathForResource:ofType:),
            @selector(if_pathForResource:ofType:inDirectory:),
            @selector(if_pathForResource:ofType:inDirectory:forLocalization:),
            @selector(if_pathsForResourcesOfType:inDirectory:),
            @selector(if_pathsForResourcesOfType:inDirectory:forLocalization:),
            @selector(if_localizedStringForKey:value:table:)
        };

        NSInteger methodCount = 11;

        for (NSInteger i = 0; i < methodCount; i++ ) {

            Method original = class_getInstanceMethod(class, originals[i]);
            Method replacement = class_getInstanceMethod(class, replacements[i]);

            BOOL didAddMethod = class_addMethod(class, originals[i], method_getImplementation(replacement), method_getTypeEncoding(replacement));

            if (didAddMethod) {
                class_replaceMethod(class, replacements[i], method_getImplementation(original), method_getTypeEncoding(original));
            }
            else {
                method_exchangeImplementations(original, replacement);
            }
        }
    });
}
*/
- (nullable NSURL *)if_URLForResource:(nullable NSString *)name withExtension:(nullable NSString *)ext {
    NSLog(@"URLForResource:%@ withExtension:%@", name, ext );
    return [self if_URLForResource:name withExtension:ext];
}

- (nullable NSURL *)if_URLForResource:(nullable NSString *)name withExtension:(nullable NSString *)ext subdirectory:(nullable NSString *)subpath {
    NSLog(@"URLForResource:%@ withExtension:%@ subdirectory:%@", name, ext, subpath );
    return [self if_URLForResource:name withExtension:ext subdirectory:subpath];
}

- (nullable NSURL *)if_URLForResource:(nullable NSString *)name withExtension:(nullable NSString *)ext subdirectory:(nullable NSString *)subpath localization:(nullable NSString *)localizationName {
    NSLog(@"URLForResource:%@ withExtension:%@ subdirectory:%@ localization:%@", name, ext, subpath, localizationName );
    return [self if_URLForResource:name withExtension:ext subdirectory:subpath localization:localizationName];
}

- (nullable NSArray<NSURL *> *)if_URLsForResourcesWithExtension:(nullable NSString *)ext subdirectory:(nullable NSString *)subpath {
    NSLog(@"URLsForResourcesWithExtension:%@ subdirectory:%@", ext, subpath );
    return [self if_URLsForResourcesWithExtension:ext subdirectory:subpath];
}

- (nullable NSArray<NSURL *> *)if_URLsForResourcesWithExtension:(nullable NSString *)ext subdirectory:(nullable NSString *)subpath localization:(nullable NSString *)localizationName {
    NSLog(@"URLsForResourcesWithExtension:%@ subdirectory:%@ localization:%@", ext, subpath, localizationName );
    return [self if_URLsForResourcesWithExtension:ext subdirectory:subpath localization:localizationName];
}

- (nullable NSString *)if_pathForResource:(nullable NSString *)name ofType:(nullable NSString *)ext {
    NSLog(@"pathForResource:%@ ofType:%@", name, ext );
    return [self if_pathForResource:name ofType:ext];
}

- (nullable NSString *)if_pathForResource:(nullable NSString *)name ofType:(nullable NSString *)ext inDirectory:(nullable NSString *)subpath {
    NSLog(@"pathForResource:%@ ofType:%@ inDirectory:%@", name, ext, subpath );
    return [self if_pathForResource:name ofType:ext inDirectory:subpath];
}

- (nullable NSString *)if_pathForResource:(nullable NSString *)name ofType:(nullable NSString *)ext inDirectory:(nullable NSString *)subpath forLocalization:(nullable NSString *)localizationName {
    NSLog(@"pathForResource:%@ ofType:%@ inDirectory:%@ forLocalization:%@", name, ext, subpath, localizationName );
    return [self if_pathForResource:name ofType:ext inDirectory:subpath forLocalization:localizationName];
}

- (NSArray<NSString *> *)if_pathsForResourcesOfType:(nullable NSString *)ext inDirectory:(nullable NSString *)subpath {
    NSLog(@"pathsForResourcesOfType:%@ inDirectory:%@", ext, subpath );
    return [self if_pathsForResourcesOfType:ext inDirectory:subpath];
}

- (NSArray<NSString *> *)if_pathsForResourcesOfType:(nullable NSString *)ext inDirectory:(nullable NSString *)subpath forLocalization:(nullable NSString *)localizationName {
    NSLog(@"pathsForResourcesOfType:%@ inDirectory:%@ forLocalization:%@", ext, subpath, localizationName );
    return [self if_pathsForResourcesOfType:ext inDirectory:subpath forLocalization:localizationName];
}

- (NSString *)if_localizedStringForKey:(NSString *)key value:(nullable NSString *)value table:(nullable NSString *)tableName {
    NSLog(@"localizedStringForKey:%@ value:%@ table:%@", key, value, tableName );
    return [self if_localizedStringForKey:key value:value table:tableName];
}

@end
