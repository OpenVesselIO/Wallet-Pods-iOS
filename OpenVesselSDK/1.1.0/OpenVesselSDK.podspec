require_relative 'installed-pods-info.rb'

Pod::Spec.new do |spec|
    spec.name         = "OpenVesselSDK"
    spec.version      = "1.1.0"
    spec.summary      = "This SDK enables connection with Vessel Wallet"
    spec.homepage     = "https://github.com/OpenVesselIO/Wallet-SDK-iOS"
    spec.license      = "OpenVessel SDK EULA"
    spec.author       = { 'OpenVessel' => 'support@openvessel.io'}
    spec.platform     = :ios, "14.0"

    spec.module_name   = "OpenVessel"
    spec.swift_version = "5.1"

    spec.frameworks = "StoreKit"

    spec.pod_target_xcconfig = {
        'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => '$(inherited) arm64',
    }

    if ENV['OV_INTERNAL_DEPLOY']&.casecmp?('YES')
        spec.module_map = "Sources/OpenVessel.modulemap"

        spec.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => "OVL_SDK_VERSION=\"#{spec.version}\"" }

        spec.source = { :git => "don't publish me", :tag => "v#{spec.version}" }

        spec.source_files       = "Sources/**/*.{h,m,mm,swift}"
        spec.prefix_header_file = "Sources/OpenVessel-Prefix.pch"

        spec.public_header_files  = "Sources/OpenVessel.h", "Sources/Public/**/*.h"
        spec.project_header_files = "Sources/Project/**/*.h"

        # spec.resource_bundles = {
        #     spec.name => [ "WalletFramework/Resources/*.{json,xml}", "WalletFramework/**/*.{lproj,xib}" ]
        # }

        spec.resources = [ "Sources/Resources/*.{json,xml,xcassets}", "Sources/**/*.{lproj,xib}" ]

        spec.script_phase = { :name => 'Bundle JS', :script => "cp -R \"#{__dir__}/WalletJS-Packed/.\" \"${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/app.jsbundle\"" }

        WalletFrameworkPods::ALL_DEPENDENCIES.each do |name, requirements|
            spec.dependency name, requirements
        end
    else
        spec.source              = { :http => "https://artifacts.openvessel.io/pods/sdk/OpenVessel-#{spec.version}.xcframework.zip" }
        spec.vendored_frameworks = "Pod Binary/#{spec.module_name}.xcframework"

        WalletFrameworkPods::EXTERNAL_DEPENDENCIES.each do |name, requirements|
            spec.dependency name, requirements
        end
    end
end
