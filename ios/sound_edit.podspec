#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint sound_edit.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'sound_edit'
  s.version          = '0.0.1'
  s.summary          = 'audio editing project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'https://everydaysoft.co.jp'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'EveryDaySoft.Inc' => 'daisuke.nagata@everydaysoft.co.jp' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '14.1'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.8'
end
