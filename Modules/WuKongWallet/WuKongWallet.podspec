Pod::Spec.new do |s|
  s.name             = 'WuKongWallet'
  s.version          = '0.1.0'
  s.summary          = 'Wallet module for TangSengDaoDao.'

  s.description      = <<-DESC
  Wallet module providing balance display, pay password management, and transaction records.
                       DESC

  s.homepage         = 'https://github.com/tangtaoit/WuKongWallet'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'tangtaoit' => 'tt@wukong.ai' }
  s.source           = { :git => 'https://github.com/tangtaoit/WuKongWallet.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'

  s.source_files = 'WuKongWallet/Classes/**/*'

  s.resource_bundles = {
    'WuKongWallet_images' => ['WuKongWallet/Assets/Images.xcassets']
  }
  s.resources = ['WuKongWallet/Assets/Lang']

  s.frameworks = 'UIKit', 'Photos'
  s.dependency 'WuKongBase'
  s.dependency 'WuKongIMSDK'
  s.dependency 'WuKongRedPackets'
  s.dependency 'WuKongTransfer'
end
