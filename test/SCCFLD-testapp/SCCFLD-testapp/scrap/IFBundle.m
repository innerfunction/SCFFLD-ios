
// --- XXX ---
@interface IFBundle : NSBundle {
    NSBundle *bundle;
}

- (id)init;

@end

@implementation IFBundle

- (id)init {
    self = [super init];
    if( self) {
        bundle = [NSBundle mainBundle];
    }
    return self;
}

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

- (nullable NSURL *)URLForResource:(nullable NSString *)name withExtension:(nullable NSString *)ext {
    return [bundle URLForResource:name withExtension:ext];
}

- (nullable NSURL *)URLForResource:(nullable NSString *)name withExtension:(nullable NSString *)ext subdirectory:(nullable NSString *)subpath {
    return [bundle URLForResource:name withExtension:ext subdirectory:subpath];
}

- (nullable NSURL *)URLForResource:(nullable NSString *)name withExtension:(nullable NSString *)ext subdirectory:(nullable NSString *)subpath localization:(nullable NSString *)localizationName {
    return [bundle URLForResource:name withExtension:ext subdirectory:subpath localization:localizationName];
}

- (nullable NSArray<NSURL *> *)URLsForResourcesWithExtension:(nullable NSString *)ext subdirectory:(nullable NSString *)subpath {
    return [bundle URLsForResourcesWithExtension:ext subdirectory:subpath];
}

- (nullable NSArray<NSURL *> *)URLsForResourcesWithExtension:(nullable NSString *)ext subdirectory:(nullable NSString *)subpath localization:(nullable NSString *)localizationName {
    return [bundle URLsForResourcesWithExtension:ext subdirectory:subpath localization:localizationName];
}

- (nullable NSString *)pathForResource:(nullable NSString *)name ofType:(nullable NSString *)ext {
    return [bundle pathForResource:name ofType:ext];
}

- (nullable NSString *)pathForResource:(nullable NSString *)name ofType:(nullable NSString *)ext inDirectory:(nullable NSString *)subpath {
    return [bundle pathForResource:name ofType:ext inDirectory:subpath];
}

- (nullable NSString *)pathForResource:(nullable NSString *)name ofType:(nullable NSString *)ext inDirectory:(nullable NSString *)subpath forLocalization:(nullable NSString *)localizationName {
    return [bundle pathForResource:name ofType:ext inDirectory:subpath forLocalization:localizationName];
}

- (NSArray<NSString *> *)pathsForResourcesOfType:(nullable NSString *)ext inDirectory:(nullable NSString *)subpath {
    return [bundle pathsForResourcesOfType:ext inDirectory:subpath];
}

- (NSArray<NSString *> *)pathsForResourcesOfType:(nullable NSString *)ext inDirectory:(nullable NSString *)subpath forLocalization:(nullable NSString *)localizationName {
    return [bundle pathsForResourcesOfType:ext inDirectory:subpath forLocalization:localizationName];
}

- (NSString *)localizedStringForKey:(NSString *)key value:(nullable NSString *)value table:(nullable NSString *)tableName {
    return [bundle localizedStringForKey:key value:value table:tableName];
}
/*
- (NSArray *)loadNibNamed:(NSString *)name owner:(id)owner options:(NSDictionary *)options {
    return [super loadNibNamed:name owner:owner options:options];
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)prepareForInterfaceBuilder {
    [super prepareForInterfaceBuilder];
}
*/
@end

// --- XXX ---

