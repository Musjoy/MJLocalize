#
# Be sure to run `pod lib lint MJLocalize.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MJLocalize'
  s.version          = '0.1.10'
  s.summary          = 'MJLocalize is use to get localized string from plist'


  s.homepage         = 'https://github.com/Musjoy/MJLocalize'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Musjoy' => 'Ray.musjoy@gmail.com' }
  s.source           = { :git => 'https://github.com/Musjoy/MJLocalize.git', :tag => "v-#{s.version}" }

  s.ios.deployment_target = '8.0'

  s.source_files = 'MJLocalize/Classes/**/*'
  
  s.user_target_xcconfig = {
    'GCC_PREPROCESSOR_DEFINITIONS' => 'MODULE_LOCALIZE'
  }

  s.dependency 'ModuleCapability', '~> 0.1.2'
  s.prefix_header_contents = '#import "ModuleCapability.h"'

end
