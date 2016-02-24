Pod::Spec.new do |s|
  s.name         = 'ACSNetworking'
  s.version      = '1.3.2'
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

  s.requires_arc = true
  s.source       = { :git => 'https://github.com/Hyosung/ACSNetworking.git', :tag => s.version.to_s }
  s.public_header_files = 'ACSNetworking/ACSNetworking.h'
  s.source_files = 'ACSNetworking/ACSNetworking.h'
  s.default_subspecs = 'Requester'

  s.subspec 'General' do |ss|

    ss.dependency 'AFNetworking', '~> 2.6.0'
    ss.source_files = 'ACSNetworking/ACSNetworkGeneral.h'
  end

  s.subspec 'Reachability' do |ss|

    ss.source_files = 'ACSNetworking/ACSReachability.{h,m}'
    ss.public_header_files = 'ACSNetworking/ACSReachability.h'

    ss.frameworks = 'SystemConfiguration'
    ss.ios.frameworks = 'CoreTelephony', 'UIKit'
  end

  s.subspec 'BaseRequester' do |ss|
    ss.dependency 'ACSNetworking/General'
    ss.source_files = 'ACSNetworking/ACS*Request.{h,m}'
    ss.public_header_files = 'ACSNetworking/ACS*Request.h'
  end

  s.subspec 'Foundation' do |ss|

    ss.source_files = 'ACSNetworking/NSData+ACSMimeType.*'
    ss.public_header_files = 'ACSNetworking/NSData+ACSMimeType.h'

    ss.ios.frameworks = 'MobileCoreServices'
    ss.osx.frameworks = 'CoreServices'
  end


  s.subspec 'Cache' do |ss|
    ss.dependency 'ACSNetworking/General'
    ss.source_files = 'ACSNetworking/ACSCache.{h,m}'
    ss.public_header_files = 'ACSNetworking/ACSCache.h'

    ss.ios.frameworks = 'UIKit'
  end

  s.subspec 'Configuration' do |ss|
    ss.dependency 'ACSNetworking/General'
    ss.dependency 'ACSNetworking/Cache'

    ss.source_files = 'ACSNetworking/ACSNetworkConfiguration.*'
    ss.public_header_files = 'ACSNetworking/ACSNetworkConfiguration.h'

    ss.ios.frameworks = 'UIKit'
  end

  s.subspec 'Requester' do |ss|
    ss.dependency 'ACSNetworking/General'
    ss.dependency 'ACSNetworking/Reachability'
    ss.dependency 'ACSNetworking/Cache'
    ss.dependency 'ACSNetworking/Configuration'
    ss.dependency 'ACSNetworking/Foundation'
    ss.dependency 'ACSNetworking/BaseRequester'

    ss.source_files = 'ACSNetworking/ACS*er.{h,m}'
    ss.public_header_files = 'ACSNetworking/ACS*er.h'

    ss.ios.frameworks = 'UIKit', 'MobileCoreServices'
    ss.osx.frameworks = 'AppKit', 'CoreServices'
  end
end
