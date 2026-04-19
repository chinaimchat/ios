Pod::Spec.new do |s|
  s.name             = 'WuKongTransfer'
  s.version          = '0.1.0'
  s.summary          = 'Transfer module for TangSengDaoDao.'

  s.description      = <<-DESC
  Transfer module providing sending, accepting, and detail viewing of transfers.
                       DESC

  s.homepage         = 'https://github.com/tangtaoit/WuKongTransfer'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'tangtaoit' => 'tt@wukong.ai' }
  s.source           = { :git => 'https://github.com/tangtaoit/WuKongTransfer.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'

  s.source_files = 'WuKongTransfer/Classes/**/*'

  s.frameworks = 'UIKit'
  s.dependency 'WuKongBase'
  s.dependency 'WuKongIMSDK'
end
