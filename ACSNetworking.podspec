Pod::Spec.new do |s|
  s.name         = 'ACSNetworking'
  s.version      = '1.3'
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
  s.source_files = 'ACSNetworking/ACSNetwork{ing, General}.h'

  s.subspec 'Reachability' do |ss|

    ss.source_files = 'ACSNetworking/ACSReachability.{h,m}'
    ss.public_header_files = 'ACSNetworking/ACSReachability.h'

    ss.frameworks = 'SystemConfiguration'
    ss.ios.frameworks = 'CoreTelephony', 'UIKit'
  end

  s.subspec 'BaseRequester' do |ss|

    ss.source_files = 'ACSNetworking/ACS{File, HTTP}Request.{h,m}'
    ss.public_header_files = 'ACSNetworking/ACS{File, HTTP}Request.h'
  end

  s.subspec 'Foundation' do |ss|

    ss.source_files = 'ACSNetworking/NSData+ACSMimeType.{h,m}'
    ss.public_header_files = 'ACSNetworking/NSData+ACSMimeType.h'

    ss.ios.frameworks = 'MobileCoreServices'
    ss.osx.frameworks = 'CoreServices'
  end


  s.subspec 'Cache' do |ss|

    ss.source_files = 'ACSNetworking/ACSCache.{h,m}'
    ss.public_header_files = 'ACSNetworking/ACSCache.h'

    ss.ios.frameworks = 'UIKit'
  end

  s.subspec 'Configuration' do |ss|
    ss.dependency 'ACSNetworking/Cache'

    ss.source_files = 'ACSNetworking/ACSNetworkConfiguration.{h,m}'
    ss.public_header_files = 'ACSNetworking/ACSNetworkConfiguration.h'

    ss.ios.frameworks = 'UIKit'
  end

  s.subspec 'Requester' do |ss|
    ss.dependency 'ACSNetworking/BaseRequester'
    ss.dependency 'ACSNetworking/Cache'
    ss.dependency 'ACSNetworking/Configuration'
    ss.dependency 'ACSNetworking/Foundation'

    ss.source_files = 'ACSNetworking/ACS{FileDownload,FileUpload,URLHTTPRequest,RequestManag}er.{h,m}'
    ss.public_header_files = 'ACSNetworking/ACS{FileDownload,FileUpload,URLHTTPRequest,RequestManag}er.h'

    ss.ios.frameworks = 'UIKit', 'MobileCoreServices'
    ss.osx.frameworks = 'AppKit', 'CoreServices'
  end
  s.dependency 'AFNetworking', '~> 2.6.0'
end
