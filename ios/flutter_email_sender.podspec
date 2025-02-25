#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'flutter_email_sender'
  s.version          = '0.0.1'
  s.summary          = 'Allows send emails from flutter using native platform functionality.'
  s.description      = <<-DESC
Allows send emails from flutter using native platform functionality.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'flutter_email_sender/Sources/flutter_email_sender/**/*.swift'
  s.dependency 'Flutter'
  
  s.ios.deployment_target = '8.0'
  s.swift_version = '5.0'
  s.resource_bundles = {'flutter_email_sender_privacy' => ['flutter_email_sender/Sources/flutter_email_sender/PrivacyInfo.xcprivacy']}
end

