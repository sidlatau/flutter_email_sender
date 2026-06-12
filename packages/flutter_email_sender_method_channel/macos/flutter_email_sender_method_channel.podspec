Pod::Spec.new do |s|
  s.name             = 'flutter_email_sender_method_channel'
  s.version          = '0.0.1'
  s.summary          = 'Allows send emails from flutter using native platform functionality.'
  s.description      = <<-DESC
Allows send emails from flutter using native platform functionality.
                       DESC
  s.homepage         = 'https://github.com/sidlatau/flutter_email_sender'
  s.license          = { :file => '../../flutter_email_sender/LICENSE' }
  s.author           = { 'sidlatau' => 'sidlatau@gmail.com' }
  s.source           = { :path => '.' }
  s.module_name      = 'flutter_email_sender_method_channel'
  s.source_files = 'flutter_email_sender_method_channel/Sources/flutter_email_sender/**/*.swift'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.14'
  s.swift_version = '5.0'
  s.resource_bundles = {'flutter_email_sender_method_channel_privacy' => ['flutter_email_sender_method_channel/Sources/flutter_email_sender/PrivacyInfo.xcprivacy']}
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
