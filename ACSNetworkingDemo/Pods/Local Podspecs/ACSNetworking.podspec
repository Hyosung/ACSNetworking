Pod::Spec.new do |s|
  s.name         = 'ACSNetworking'
  s.version      = '0.0.1'
  s.summary      = 'On the basis of AFNetworking encapsulation.'
  s.description  = <<-DESC
                   On the basis of AFNetworking encapsulation, more convenient, more concise.
                   DESC
  s.homepage     = 'https://github.com/Hyosung/ACSNetworking'
  # s.screenshots  = 'www.example.com/screenshots_1.gif', 'www.example.com/screenshots_2.gif'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author             = { 'Stoney' => 'sy92710xx@gmail.com' }
  s.social_media_url   = 'http://blog.csdn.net/sy431256wr'
  s.platform     = :ios, '6.0'
  s.requires_arc = true
  s.source       = { :git => 'https://github.com/Hyosung/ACSNetworking.git', :tag => '0.0.1' }
  s.source_files  = 'ACSNetworking', 'ACSNetworking/**/*.{h,m}'
  # s.exclude_files = 'Classes/Exclude'
  # s.public_header_files = 'Classes/**/*.h'
  # s.resource  = 'icon.png'
  # s.resources = 'Resources/*.png'
  # s.preserve_paths = 'FilesToSave', 'MoreFilesToSave'
  # s.framework  = 'SomeFramework'
  # s.frameworks = 'SomeFramework', 'AnotherFramework'
  # s.library   = 'iconv'
  # s.libraries = 'iconv', 'xml2'
  # s.requires_arc = true
  # s.xcconfig = { 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2' }
  s.dependency 'AFNetworking', '~> 2.5.4'
end
