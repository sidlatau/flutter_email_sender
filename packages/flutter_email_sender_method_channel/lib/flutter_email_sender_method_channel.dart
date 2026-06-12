import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_email_sender_platform_interface/flutter_email_sender_platform_interface.dart';

class MethodChannelFlutterEmailSender extends FlutterEmailSenderPlatform {
  static const MethodChannel _channel = MethodChannel('flutter_email_sender');

  static const EmailCapabilities _mobileCapabilities = EmailCapabilities(
    isAvailable: true,
    supportsCc: true,
    supportsBcc: true,
    supportsSubject: true,
    supportsPlainTextBody: true,
    supportsHtmlBody: true,
    supportsAttachments: true,
  );

  static const EmailCapabilities _macosCapabilities = EmailCapabilities(
    isAvailable: true,
    supportsCc: false,
    supportsBcc: false,
    supportsSubject: true,
    supportsPlainTextBody: true,
    supportsHtmlBody: false,
    supportsAttachments: true,
  );

  @override
  Future<void> send(Email email) async {
    final capabilities = await getCapabilities();
    capabilities.validateEmail(email, platformName: _platformName);
    await _channel.invokeMethod<void>('send', email.toJson());
  }

  @override
  Future<EmailCapabilities> getCapabilities() async {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => _mobileCapabilities,
      TargetPlatform.macOS => _macosCapabilities,
      _ => const EmailCapabilities.none(),
    };
  }

  String get _platformName {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.fuchsia => 'fuchsia',
      TargetPlatform.linux => 'linux',
      TargetPlatform.windows => 'windows',
    };
  }
}
