platform :ios, '13.0'

ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

install! 'cocoapods', :disable_input_output_paths => true

require File.expand_path(File.join('..', 'Flutter', 'podhelper.rb'), __FILE__)

target 'Runner' do
  use_frameworks! :linkage => :static

  install_all_flutter_pods File.dirname(File.realpath(__FILE__))

  target 'RunnerTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.build_configurations.each do |config|
    config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'x86_64'
    config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
  end

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['DEFINES_MODULE'] = 'YES'
    end
  end
end