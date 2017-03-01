Pod::Spec.new do |s|
  s.name        = "SCFFLD"
  s.version     = "0.9.2"
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
      :git => "https://github.com/innerfunction/SCFFLD-ios.git", :tag => "0.9.2" }
  s.source_files            = "SCFFLD/*.{h,m}", "SCFFLD/{app,ioc,ui,uri,util}/*.{h,m}", "SCFFLD/Externals/**/*.{h,m}"
  s.exclude_files           = "SCFFLD/Externals/ISO8601DateFormatter/*.m", "SCFFLD/Externals/JSONKit/*.m", "SCFFLD/Externals/ZipArchive/**/*.{h,c,mm}"
  s.public_header_files     = 'SCFFLD/util/*.h', 'SCFFLD/uri/*.h', 'SCFFLD/ioc/*.h', 'SCFFLD/app/*.h', 'SCFFLD/ui/*.h'
  s.requires_arc            = true
  s.compiler_flags          = '-w'
  s.frameworks              = "UIKit", "Foundation"
  s.libraries               = "z"
  s.xcconfig                = {
      "HEADER_SEARCH_PATHS" => "$(SRCROOT)/**",
      'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
      # NOTE: The following flag is to disable a warning generated from IFTableViewController.h due to usage
      # of a deprecated API; it can be removed once the class is updated to remove the warning.
      'OTHER_LDFLAGS' => '-w' }
  s.dependency 'ZipArchive'

  s.subspec 'noarc' do |sp|
    sp.source_files         = "SCFFLD/Externals/ISO8601DateFormatter/*.{h,m}", "SCFFLD/Externals/JSONKit/*.{h,m}"
    sp.requires_arc         = false
    sp.compiler_flags       = '-w'
  end

end
