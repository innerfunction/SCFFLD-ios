Pod::Spec.new do |s|
    s.name        = "SCFFLD"
    s.version     = "0.9.5"
    s.summary     = "Dependency Injection framework for iOS"
    s.description = <<-DESC
Core functionality for the SCFFLD dependency injection (DI) framework for iOS.
This library provides:
* Internal URI space;
* Inversion of Control (IoC) container functionality;
* Actions/events through target containers;
* Basic UI views;
* Supporting utility functions.
    DESC
    s.homepage                = "https://github.com/innerfunction/SCFFLD-ios"
    s.license                 = {
      :type => "Apache License, Version 2.0",
      :file => "LICENSE" }
    s.author                  = { "Julian Goacher" => "julian.goacher@innerfunction.com" }
    s.platform                = :ios
    s.ios.deployment_target   = '8.0'
    s.source                  = {
      #:git => "https://github.com/innerfunction/SCFFLD-ios.git", :tag => "0.9.5" }
      :git => '/Users/juliangoacher/Work/Github/SCFFLD-ios/.git' }

    s.frameworks              = "UIKit", "Foundation"

    #s.libraries               = "z"
    s.xcconfig                = {
      "HEADER_SEARCH_PATHS" => "$(SRCROOT)/**",
      'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
      # NOTE: The following flag is to disable a warning generated from SCTableViewController.h due to usage
      # of a deprecated API; it can be removed once the class is updated to remove the warning.
      'OTHER_LDFLAGS' => '-w' }

    s.subspec 'NoArc' do |noarc|
        noarc.source_files = 'SCFFLD/util/ISO8601DateFormatter.*', 'SCFFLD/Externals/JSONKit/*';
        noarc.requires_arc = false;
        noarc.compiler_flags = '-w';
        noarc.public_header_files = 'SCFFLD/util/ISO8601DateFormatter.h', 'SCFFLD/Externals/JSONKit/*.h';
    end

    s.subspec 'Core' do |core|
        core.source_files = 'SCFFLD/{core,util}/*.{h,m}';
        core.public_header_files = 'SCFFLD/{core,util}/*.h';
        core.requires_arc = true;
        core.compiler_flags = '-w';
        core.libraries = 'z';
        core.dependency 'SCFFLD/NoArc';
        core.dependency 'ZipArchive'
    end

    s.subspec 'DB' do |db|
        db.source_files = 'SCFFLD/db/*.{h,m}';
        db.public_header_files = 'SCFFLD/db/*.h';
        db.requires_arc = true;
        db.compiler_flags = '-w';
        db.libraries = 'sqlite3'
        db.dependency 'SCFFLD/Core';
    end

    s.subspec 'HTTP' do |http|
        http.source_files = 'SCFFLD/http/*.{h,m}';
        http.public_header_files = 'SCFFLD/http/*.h';
        http.requires_arc = true;
        http.compiler_flags = '-w';
        http.dependency 'SCFFLD/Core';
        http.dependency 'Q';
        http.dependency 'SSKeychain';
        http.dependency 'MessagePack';
    end

    s.subspec 'IOC' do |ioc|
        ioc.source_files = 'SCFFLD/ioc/*.{h,m}', 'SCFFLD/ioc/{app,ui}/*.{h,m}', 'SCFFLD/uri/*.{h,m}';
        ioc.public_header_files = 'SCFFLD/ioc/*.h', 'SCFFLD/ioc/{app,ui}/*.h', 'SCFFLD/uri/*.h';
        ioc.requires_arc = true;
        ioc.compiler_flags = '-w';
        ioc.dependency 'SCFFLD/Core';
        ioc.dependency 'JTSImageViewController'
        ioc.dependency 'SWRevealViewController'
    end

end
