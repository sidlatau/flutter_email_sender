#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_email_sender'
  s.version          = '8.0.0'
  s.summary          = 'Allows sending emails from Flutter using native platform functionality.'
  s.description      = <<-DESC
Allows sending emails from Flutter using native platform functionality.
                       DESC
  s.homepage         = 'https://github.com/sidlatau/flutter_email_sender'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'flutter_email_sender/Sources/flutter_email_sender/**/*.swift'
  s.dependency 'FlutterMacOS'
  
  s.platform = :osx, '10.13'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
  s.resource_bundles = {'flutter_email_sender_privacy' => ['flutter_email_sender/Sources/flutter_email_sender/PrivacyInfo.xcprivacy']}
end
