# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

target 'ARConnect' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  # Pods for ARConnect
  use_frameworks!

  pod 'Firebase/Database'
  pod 'Firebase/Auth'
  pod 'Firebase/Storage'
  pod 'Firebase/Core'
  pod 'RxSwift',                '~> 4.4', inhibit_warnings: true
  pod 'RxCocoa',                '~> 4.4'
  pod 'SwiftLint'
  target "ARConnectTests" do
    pod 'Quick'
    pod 'Nimble'
    pod 'RxNimble'
    pod 'RxBlocking'
    pod 'RxTest'
  end
# pod 'RxAtomic',               '~> 4.0', :modular_headers => true
end

post_install do |installer|
    sharedLibrary = installer.aggregate_targets.find { |aggregate_target| aggregate_target.name == 'Pods-[ARConnect-ARConnectTests]' }
    installer.aggregate_targets.each do |aggregate_target|
        if aggregate_target.name == 'Pods-[ARConnect]'
            aggregate_target.xcconfigs.each do |config_name, config_file|
                sharedLibraryPodTargets = sharedLibrary.pod_targets
                aggregate_target.pod_targets.select { |pod_target| sharedLibraryPodTargets.include?(pod_target) }.each do |pod_target|
                    pod_target.specs.each do |spec|
                        frameworkPaths = unless spec.attributes_hash['ios'].nil? then spec.attributes_hash['ios']['vendored_frameworks'] else spec.attributes_hash['vendored_frameworks'] end || Set.new
                        frameworkNames = Array(frameworkPaths).map(&:to_s).map do |filename|
                            extension = File.extname filename
                            File.basename filename, extension
                        end
                    end
                    frameworkNames.each do |name|
                        if name != '[DUPLICATED_FRAMEWORK_1]' && name != '[DUPLICATED_FRAMEWORK_2]'
                            raise("Script is trying to remove unwanted flags: #{name}. Check it out!")
                        end
                        puts "Removing #{name} from OTHER_LDFLAGS"
                        config_file.frameworks.delete(name)
                    end
                end
            end
            xcconfig_path = aggregate_target.xcconfig_path(config_name)
            config_file.save_as(xcconfig_path)
        end
    end
end
