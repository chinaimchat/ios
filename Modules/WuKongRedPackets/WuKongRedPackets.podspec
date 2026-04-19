Pod::Spec.new do |s|
  s.name             = 'WuKongRedPackets'
  s.version          = '0.1.0'
  s.summary          = 'Red Packet module for TangSengDaoDao.'

  s.description      = <<-DESC
  Red Packet module providing sending, opening, and detail viewing of red packets.
                       DESC

  s.homepage         = 'https://github.com/tangtaoit/WuKongRedPackets'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'tangtaoit' => 'tt@wukong.ai' }
  s.source           = { :git => 'https://github.com/tangtaoit/WuKongRedPackets.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'

  s.source_files = 'WuKongRedPackets/Classes/**/*'
  s.resources = ['WuKongRedPackets/Assets/Lang']

  s.frameworks = 'UIKit'
  s.dependency 'WuKongBase'
  s.dependency 'WuKongIMSDK'
end
