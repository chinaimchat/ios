#
# Be sure to run `pod lib lint WuKongIMSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'WuKongIMSDK'
  s.version          = '1.1.0'
  s.summary          = '悟空IM是一款简单，高效，支持完全私有化的即时通讯.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
悟空IM是一款简单，高效，支持完全私有化的即时通讯，提供群聊，点对点通讯解决方案.
                       DESC

  s.homepage         = 'https://github.com/WuKongIM/WuKongIMiOSSDK'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'tangtaoit' => 'tt@tgo.ai' }
  s.source           = { :git => "https://github.com/WuKongIM/WuKongIMiOSSDK.git" }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  s.platform     = :ios, '11.0'
  s.requires_arc = true
  # Build as static framework to avoid pod-target dynamic link missing symbols.
  s.static_framework = true

  s.ios.deployment_target = '11.0'
  
  # Use xcframework codecs only (device + simulator). Avoid legacy -l* static library linkage.
  s.vendored_frameworks = [
    'WuKongIMSDK/Classes/private/arm/lib/libopencore-amrnb.xcframework',
    'WuKongIMSDK/Classes/private/arm/lib/libopencore-amrwb.xcframework',
    'WuKongIMSDK/Classes/private/arm/lib/libvo-amrwbenc.xcframework'
  ]
  s.preserve_paths = 'WuKongIMSDK/Classes/private/arm/lib/*.xcframework'

  # 只收录源码，避免把二进制(.a/.framework/xcframework内容)当作源码参与编译/链接
  s.source_files = 'WuKongIMSDK/Classes/**/*.{h,m,mm,c,cc,cpp,swift}'
  s.public_header_files =  'WuKongIMSDK/Classes/**/*.h'
  s.private_header_files = 'WuKongIMSDK/Classes/private/**/*.h'
  s.frameworks = 'UIKit', 'MapKit', 'Security'
#  s.xcconfig = {
#      'ENABLE_BITCODE' => 'NO',
#      "OTHER_LDFLAGS" => "-ObjC"
#  }
  
  s.resource_bundles = {
    'WuKongIMSDK' => ['WuKongIMSDK/Assets/*.png','WuKongIMSDK/Assets/Migrations/*']
  }

  # 防止 xcframework 内部的 Info.plist 被 source_files 误收录，触发 “Multiple commands produce .../WuKongIMSDK.framework/Info.plist”
  s.exclude_files = 'WuKongIMSDK/Classes/private/arm/lib/**/*.xcframework/**'

  # 编解码已含 ios-arm64-simulator 切片；勿再排除 arm64，否则 Apple Silicon 模拟器会与主工程 arm64 链接不一致。
  s.pod_target_xcconfig = {
      'DEFINES_MODULE' => 'YES'
  }

  s.dependency 'CocoaAsyncSocket', '~> 7.6.5'
  s.dependency 'FMDB/SQLCipher', '~>2.7.5'
  s.dependency '25519', '~>2.0.2'
end
