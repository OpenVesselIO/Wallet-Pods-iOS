require_relative '.scripts/env'
require_relative '.installed-pods-info'

require 'shellwords'
require 'json'

module OpenVessel

    def self.git!(*args)
        return Pod::Executable.execute_command(:git, Array(args).flatten, true)
    end

end

Pod::Spec.new do |spec|
    spec.name         = "OpenVesselSDK"
    spec.version      = "1.14.0-preview.1"
    spec.summary      = "This SDK enables connection with Vessel Wallet"
    spec.homepage     = "https://github.com/OpenVesselIO/Wallet-SDK-iOS"
    spec.license      = "OpenVessel SDK EULA"
    spec.author       = { 'OpenVessel' => 'support@openvessel.io'}
    spec.platform     = :ios, "13.0"

    spec.module_name   = FRAMEWORK_NAME
    spec.swift_version = "5.1"

    spec.frameworks = "StoreKit", "Combine", "UIKit"

    spec.pod_target_xcconfig = {
        'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => '$(inherited) arm64',
    }

    if IS_INTERNAL_DEPLOY
        spec.module_map = "Sources/OpenVessel.modulemap"

        if IS_LOCAL_USAGE
            spec.source = { :git => "don't publish me", :tag => "v#{spec.version}" }
            contracts_version = '1.0.0'
        else
            spec.source = {
                :git => 'https://github.com/OpenVesselIO/Wallet-Framework-iOS.git',
                :branch => OpenVessel.git!('branch', '--show-current').strip,
                :commit => OpenVessel.git!('rev-parse', 'HEAD').strip
            }
            contracts_version = spec.version
        end

        spec.subspec 'Default' do |sp|
            sp.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => "OVL_SDK_VERSION=\\\"#{spec.version}\\\"" }

            sp.source_files       = "Sources/**/*.{h,m,mm,swift}"
            sp.prefix_header_file = "Sources/OpenVessel-Prefix.pch"

            sp.public_header_files  = "Sources/OpenVessel.h", "Sources/Public/**/*.h"
            sp.project_header_files = "Sources/Project/**/*.h"

            sp.resources = [ "Sources/Resources/*.{json,xml,xcassets}", "Sources/**/*.{lproj,xib}" ]

            WalletFrameworkPods::ALL_DEPENDENCIES.each do |name, requirements|
                sp.dependency name, requirements
            end

            sp.dependency 'OpenVessel-InternalContracts', contracts_version.to_s
        end

        unless TARGET_BRANCH == MASTER_BRANCH_NAME
            spec.subspec TARGET_BRANCH.capitalize do |sp|
                sp.dependency "#{spec.name}/Default"
            end
        end

        spec.default_subspec = 'Default'
    else
        spec.homepage = "https://openvessel.io"
        spec.source = {
            :http => "https:#{BINARY_ARTIFACTS_URL_BASE}/#{spec.module_name}-#{spec.version}.#{XCFRAMEWORK_EXT}.#{ZIP_EXT}"
        }
        spec.vendored_frameworks = "#{REL_PATH_TO_POD_BINARY_DIR}/#{spec.module_name}.#{XCFRAMEWORK_EXT}"
        spec.script_phase = {
            :name => 'Validate Project',
            :script => 'abort "\\n\\n'\
                       'Please ensure that you installed the `cocoapods-openvessel` plugin:\\n\\n'\
                       '1. Run the following command in Terminal: `sudo gem install cocoapods-openvessel`\\n'\
                       '2. Add the following line to the Podfile: `plugin \'cocoapods-openvessel\'`\\n'\
                       '3. Install pods once again'\
                       '\\n\\n" if not ENV["OVL_PATCHED"]&.casecmp?("YES")',
            :shell_path => '/usr/bin/env ruby',
            :execution_position => :before_compile
        }

        WalletFrameworkPods::EXTERNAL_DEPENDENCIES.each do |name, requirements|
            spec.dependency name, requirements
        end
    end
end
