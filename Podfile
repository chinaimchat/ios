# Uncomment the next line to define a global platform for your project
 platform :ios, '15.0'
workspace 'TangSengDaoDaoiOS.xcworkspace'

post_install do |installer|
    # AFNetworking: netinet6/in6.h is a private Darwin header in Xcode 15+; netinet/in.h is sufficient.
    af_files = [
      File.join(installer.sandbox.root, 'AFNetworking/AFNetworking/AFNetworkReachabilityManager.m'),
      File.join(installer.sandbox.root, 'AFNetworking/AFNetworking/AFURLSessionManager.m'),
      File.join(installer.sandbox.root, 'AFNetworking/AFNetworking/AFHTTPSessionManager.m')
    ]
    af_files.each do |af_file|
      next unless File.exist?(af_file)
      File.chmod(0644, af_file) rescue nil
      contents = File.read(af_file)
      patched = contents.gsub(/#import <netinet6\/in6\.h>\n/, '')
      File.write(af_file, patched) if patched != contents
    end

    # 填写你自己的开发者团队的team id
    dev_team = "H8PU463W68"
    project = installer.aggregate_targets[0].user_project
    project.targets.each do |target|
        target.build_configurations.each do |config|
            if dev_team.empty? and !config.build_settings['DEVELOPMENT_TEAM'].nil?
                dev_team = config.build_settings['DEVELOPMENT_TEAM']
            end
        end
    end
    
    # Fix bundle targets' 'Signing Certificate' to 'Sign to Run Locally'
    installer.pods_project.targets.each do |target|
        if target.name.include?('SocketRocket')
            target.build_configurations.each do |config|
                config.build_settings['GCC_INPUT_FILETYPE'] = 'sourcecode.c.objc'
            end
        end
        target.build_configurations.each do |config|
            if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
              config.build_settings['DEVELOPMENT_TEAM'] = dev_team
            end
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
            config.build_settings['ENABLE_BITCODE'] = 'NO'
            # BuglyPro 若存在则使用其模拟器切片；仅在 legacy Bugly 且缺 arm64-simulator 时排除 arm64
            buglypro_xcframework_path = File.join(installer.sandbox.root.to_s, '..', 'Modules', 'WuKongBase', 'WuKongBase', 'BuglyPro.xcframework')
            bugly_xcframework_path = File.join(installer.sandbox.root.to_s, '..', 'Modules', 'WuKongBase', 'WuKongBase', 'Bugly.xcframework')

            if File.exist?(buglypro_xcframework_path)
              config.build_settings.delete('EXCLUDED_ARCHS[sdk=iphonesimulator*]')
            elsif File.exist?(bugly_xcframework_path)
              config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
            else
              config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
            end
            config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'NO'
        end
    end

    # 主工程与 Pods 保持一致：BuglyPro 下不排除 arm64；legacy Bugly 下排除 arm64 模拟器
    buglypro_xcframework_path = File.join(installer.sandbox.root.to_s, '..', 'Modules', 'WuKongBase', 'WuKongBase', 'BuglyPro.xcframework')
    bugly_xcframework_path = File.join(installer.sandbox.root.to_s, '..', 'Modules', 'WuKongBase', 'WuKongBase', 'Bugly.xcframework')
    project.targets.each do |target|
        target.build_configurations.each do |config|
            if File.exist?(buglypro_xcframework_path)
                config.build_settings.delete('EXCLUDED_ARCHS[sdk=iphonesimulator*]')
            elsif File.exist?(bugly_xcframework_path)
                config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
            else
                config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
            end
        end
    end
    # 去掉「模拟器排除 arm64」：Apple Silicon 需 arm64 模拟器切片；与 x86_64 Pod 产物混链会 Undefined symbol。
    Dir.glob(File.join(installer.sandbox.root.to_s, 'Target Support Files', '**', '*.xcconfig')).each do |xcconfig_file|
        content = File.read(xcconfig_file)
        cleaned = content.gsub(/^\s*EXCLUDED_ARCHS\[sdk=iphonesimulator\*\]\s*=\s*arm64\s*\n/, '')
        File.write(xcconfig_file, cleaned) if cleaned != content
    end

    # 旧版 Swift Pod 会引用 libswiftCompatibility*；用 DEVELOPER_DIR（链接时 $(TOOLCHAIN_DIR) 可能指向无效 cryptex 路径）。
    swift_ld = '$(DEVELOPER_DIR)/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/$(PLATFORM_NAME)'
    swift_compat = " -L\"#{swift_ld}\" -lswiftCompatibility56 -lswiftCompatibilityConcurrency -lswiftCompatibilityPacks"
    # CocoaPods 生成的 WuKongIMSDK-xcframeworks.sh 对三个 codec 使用同一目标目录，后者覆盖前者，导致主工程 -lopencore-amrnb 等找不到 .a
    wk_im_xcff = File.join(installer.sandbox.root, 'Target Support Files', 'WuKongIMSDK', 'WuKongIMSDK-xcframeworks.sh')
    if File.exist?(wk_im_xcff)
      xcs = File.read(wk_im_xcff)
      xcs2 = xcs
        .gsub('lib/libopencore-amrnb.xcframework" "WuKongIMSDK" "library"', 'lib/libopencore-amrnb.xcframework" "WuKongIMSDK/amrnb" "library"')
        .gsub('lib/libopencore-amrwb.xcframework" "WuKongIMSDK" "library"', 'lib/libopencore-amrwb.xcframework" "WuKongIMSDK/amrwb" "library"')
        .gsub('lib/libvo-amrwbenc.xcframework" "WuKongIMSDK" "library"', 'lib/libvo-amrwbenc.xcframework" "WuKongIMSDK/voamrwbenc" "library"')
      File.write(wk_im_xcff, xcs2) if xcs2 != xcs
    end
    extra_amr_paths = ' "${PODS_XCFRAMEWORKS_BUILD_DIR}/WuKongIMSDK/amrnb" "${PODS_XCFRAMEWORKS_BUILD_DIR}/WuKongIMSDK/amrwb" "${PODS_XCFRAMEWORKS_BUILD_DIR}/WuKongIMSDK/voamrwbenc"'
    Dir.glob(File.join(installer.sandbox.root.to_s, 'Target Support Files', '**', '*.xcconfig')).each do |xcconfig_file|
      content = File.read(xcconfig_file)
      next unless content.include?('PODS_XCFRAMEWORKS_BUILD_DIR}/WuKongIMSDK"') && content =~ /^LIBRARY_SEARCH_PATHS = /
      next if content.include?('WuKongIMSDK/amrnb')
      content = content.sub(
        /^(LIBRARY_SEARCH_PATHS = \$\(inherited\) "\$\{PODS_XCFRAMEWORKS_BUILD_DIR\}\/WuKongIMSDK")/,
        "\\1#{extra_amr_paths}"
      )
      File.write(xcconfig_file, content)
    end

    Dir.glob(File.join(installer.sandbox.root.to_s, 'Target Support Files', 'Pods-TangSengDaoDaoiOSBase-*', '*.xcconfig')).each do |xcconfig_file|
        content = File.read(xcconfig_file)
        next unless content =~ /^OTHER_LDFLAGS = /
        content = content.gsub(
          / -L"\$\(TOOLCHAIN_DIR\)\/usr\/lib\/swift\/\$\(PLATFORM_NAME\)" -lswiftCompatibility56 -lswiftCompatibilityConcurrency -lswiftCompatibilityPacks/,
          swift_compat
        )
        unless content.include?('swiftCompatibility56')
          content = content.sub(/^(OTHER_LDFLAGS = .+)$/, "\\1#{swift_compat}")
        end
        File.write(xcconfig_file, content)
    end

    # libwebp headers use repo-root paths (e.g. yuv.h → "src/dsp/dsp.h"). Module and some Clang
    # invocations consult HEADER_SEARCH_PATHS, not only USER_HEADER_SEARCH_PATHS.
    installer.pods_project.targets.each do |target|
      next unless target.name == 'libwebp'
      target.build_configurations.each do |config|
        hs = config.build_settings['HEADER_SEARCH_PATHS'] || '$(inherited)'
        next if hs.to_s.include?('libwebp')
        config.build_settings['HEADER_SEARCH_PATHS'] = %(#{hs} "$(PODS_ROOT)/libwebp")
      end
    end

    project.save
    installer.pods_project.save
end


abstract_target 'TangSengDaoDaoiOSBase' do
  
#  pod 'lottie-ios', '~> 2.5.3'
  pod 'Socket.IO-Client-Swift'
  pod 'SSZipArchive', '~> 2.2.3'
  pod 'SocketRocket', '~> 0.7.1'
  pod 'Aspects'
  pod 'ReactiveObjC'

  target 'TangSengDaoDaoiOS' do
    project 'TangSengDaoDaoiOS.xcodeproj'
    
  # WuKongIMSDK contains static binaries/xcframework slices; use static linkage for pods.
  use_frameworks! :linkage => :static
  pod 'YBImageBrowser/NOSD', :git=>'https://github.com/tangtaoit/YBImageBrowser.git'
  pod 'YYImage/libwebp', :git => 'https://github.com/tangtaoit/YYImage.git'
  pod 'AsyncDisplayKit', :git => 'https://github.com/tangtaoit/AsyncDisplayKit.git'
  pod 'librlottie', :git => 'https://github.com/tangtaoit/librlottie.git'
  
  pod 'WuKongIMSDK',  :path => './Modules/WuKongIMiOSSDK'   ## WuKongBase 基础工具包  源码地址 https://github.com/WuKongIM/WuKongIMiOSSDK
#  pod 'WuKongIMSDK',  :path => '../../../wukongIM/iOS/WuKongIMiOSSDK'
#  pod  'WuKongIMSDK', '~> 1.0.2' ## 源码地址 https://github.com/WuKongIM/WuKongIMiOSSDK
  pod 'WuKongBase',  :path => './Modules/WuKongBase'   ## WuKongBase 基础工具包
  pod 'WuKongLogin', :path => './Modules/WuKongLogin'  ##  登录模块
  pod 'WuKongContacts', :path => './Modules/WuKongContacts'  ## 联系人模块
  pod 'WuKongDataSource', :path => './Modules/WuKongDataSource'  ## 数据源
  pod 'WuKongAdvanced', :path => './Modules/WuKongAdvanced'  ## 高级功能（阅后即焚、反应等）
  pod 'WuKongFile', :path => './Modules/WuKongFile'  ## 文件消息
  pod 'WuKongGroupManager', :path => './Modules/WuKongGroupManager'  ## 群管理
  pod 'WuKongSecurity', :path => './Modules/WuKongSecurity'  ## 安全/加密相关
  pod 'WuKongSmallVideo', :path => './Modules/WuKongSmallVideo'  ## 小视频
  pod 'WuKongStickerStore', :path => './Modules/WuKongStickerStore'  ## 表情商店
  pod 'WuKongFavorite', :path => './Modules/WuKongFavorite'  ## 收藏
  pod 'WuKongTransfer', :path => './Modules/WuKongTransfer'  ## 转账模块（钱包扫码转账依赖，需先于 Wallet）
  pod 'WuKongRedPackets', :path => './Modules/WuKongRedPackets'  ## 红包模块
  pod 'WuKongWallet', :path => './Modules/WuKongWallet'  ## 钱包模块
  pod 'WuKongPinned', :path => './Modules/WuKongPinned'  ## 消息置顶
  pod 'WuKongCustomerService', :path => './Modules/WuKongCustomerService'  ## 客服模块（热线/客服入口）
  pod 'WuKongRichTextEditor', :path => './Modules/WuKongRichTextEditor'  ## 富文本消息与编辑器
  pod 'LLLabel', :path => './Modules/LLLabel'  ## 标签模块
  end
  
end


