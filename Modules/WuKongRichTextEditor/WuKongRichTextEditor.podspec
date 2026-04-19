#
# Be sure to run `pod lib lint WuKongRichTextEditor.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'WuKongRichTextEditor'
  s.version          = '0.1.0'
  s.summary          = 'A short description of WuKongRichTextEditor.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/3895878/WuKongRichTextEditor'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '3895878' => 'tangtao@tgo.ai' }
  s.source           = { :git => 'https://github.com/3895878/WuKongRichTextEditor.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '12.0'

  s.source_files = 'WuKongRichTextEditor/Classes/**/*'
  
  s.resources = ['WuKongRichTextEditor/Assets/Lang','WuKongRichTextEditor/Assets/Other',"WuKongRichTextEditor/Assets/Images/ZSS*.png", "WuKongRichTextEditor/Assets/js/ZSSRichTextEditor.js", "WuKongRichTextEditor/Assets/js/editor.html", "**/jQuery.js", "WuKongRichTextEditor/Assets/js/JSBeautifier.js"]
  s.resource_bundles = {
    'WuKongRichTextEditor_images' => ['WuKongRichTextEditor/Assets/Images.xcassets'],
  }
  
  s.frameworks = "CoreGraphics", "CoreText"

  
  s.dependency "WuKongBase"
  s.dependency 'WuKongIMSDK'
  

end
