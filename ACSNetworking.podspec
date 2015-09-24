Pod::Spec.new do |s|
  s.name         = 'ACSNetworking'
  s.version      = '1.0.0'
  s.summary      = 'On the basis of AFNetworking encapsulation.'
  s.description  = <<-DESC
                   On the basis of AFNetworking encapsulation, more convenient, more concise.
                   DESC
  s.homepage     = 'https://github.com/Hyosung/ACSNetworking'
  s.license      = 'MIT'
  s.authors      = { 'Stoney' => 'sy92710xx@gmail.com' }
  s.social_media_url   = 'http://weibo.com/sy4312xx'
  #'http://blog.csdn.net/sy431256wr'
  s.ios.deployment_target = '7.0'
  s.osx.deployment_target = '10.9'
  #s.watchos.deployment_target = '2.0'
  s.requires_arc = true
  s.source       = { :git => 'https://github.com/Hyosung/ACSNetworking.git', :tag => s.version.to_s }
  s.source_files = 'ACSNetworking/**/*.{h,m}'
  s.ios.frameworks = 'MobileCoreServices', 'UIKit', 'CoreTelephony'
  s.osx.frameworks = 'CoreServices', 'AppKit'
  s.frameworks = 'Foundation', 'SystemConfiguration'
  s.dependency 'AFNetworking', '~> 2.6.0'
end
