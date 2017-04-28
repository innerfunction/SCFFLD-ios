//
//  NSBundle+NSBundle_IF.h
//  SCFFLD
//
//  Created by Julian Goacher on 21/03/2017.
//  Copyright © 2017 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSBundle (IF)

- (nullable NSURL *)if_URLForResource:(nullable NSString *)name withExtension:(nullable NSString *)ext;

- (nullable NSURL *)if_URLForResource:(nullable NSString *)name withExtension:(nullable NSString *)ext subdirectory:(nullable NSString *)subpath;

- (nullable NSURL *)if_URLForResource:(nullable NSString *)name withExtension:(nullable NSString *)ext subdirectory:(nullable NSString *)subpath localization:(nullable NSString *)localizationName;

- (nullable NSArray<NSURL *> *)if_URLsForResourcesWithExtension:(nullable NSString *)ext subdirectory:(nullable NSString *)subpath;

- (nullable NSArray<NSURL *> *)if_URLsForResourcesWithExtension:(nullable NSString *)ext subdirectory:(nullable NSString *)subpath localization:(nullable NSString *)localizationName;

- (nullable NSString *)if_pathForResource:(nullable NSString *)name ofType:(nullable NSString *)ext;

- (nullable NSString *)if_pathForResource:(nullable NSString *)name ofType:(nullable NSString *)ext inDirectory:(nullable NSString *)subpath;

- (nullable NSString *)if_pathForResource:(nullable NSString *)name ofType:(nullable NSString *)ext inDirectory:(nullable NSString *)subpath forLocalization:(nullable NSString *)localizationName;

- (NSArray<NSString *> *)if_pathsForResourcesOfType:(nullable NSString *)ext inDirectory:(nullable NSString *)subpath;

- (NSArray<NSString *> *)if_pathsForResourcesOfType:(nullable NSString *)ext inDirectory:(nullable NSString *)subpath forLocalization:(nullable NSString *)localizationName;

- (NSString *)if_localizedStringForKey:(NSString *)key value:(nullable NSString *)value table:(nullable NSString *)tableName;

@end
