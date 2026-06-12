import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_email_sender_platform_interface/flutter_email_sender_platform_interface.dart';

class MethodChannelFlutterEmailSender extends FlutterEmailSenderPlatform {
  MethodChannelFlutterEmailSender();

  static const MethodChannel _channel = MethodChannel('flutter_email_sender');
  static const String _getCapabilitiesMethod = 'getCapabilities';

  static void registerWith() {
    FlutterEmailSenderPlatform.instance = MethodChannelFlutterEmailSender();
  }

  static const EmailCapabilities _mobileCapabilities = EmailCapabilities(
    canSend: true,
    supportsCc: true,
    supportsBcc: true,
    supportsSubject: true,
    supportsPlainTextBody: true,
    supportsHtmlBody: true,
    supportsAttachments: true,
  );

  static const EmailCapabilities _macosCapabilities = EmailCapabilities(
    canSend: true,
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
    capabilities.validateEmail(email, platformName: defaultTargetPlatform.name);
    await _channel.invokeMethod<void>('send', email.toJson());
  }

  @override
  Future<EmailCapabilities> getCapabilities() async {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS || TargetPlatform.macOS =>
        _nativeCapabilities(),
      _ => const EmailCapabilities.none(),
    };
  }

  Future<EmailCapabilities> _nativeCapabilities() async {
    final capabilities = await _channel.invokeMapMethod<String, bool>(
      _getCapabilitiesMethod,
    );

    final defaults = switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => _mobileCapabilities,
      TargetPlatform.macOS => _macosCapabilities,
      _ => const EmailCapabilities.none(),
    };

    return EmailCapabilities(
      canSend: capabilities?['canSend'] ?? defaults.canSend,
      supportsCc: defaults.supportsCc,
      supportsBcc: defaults.supportsBcc,
      supportsSubject: defaults.supportsSubject,
      supportsPlainTextBody: defaults.supportsPlainTextBody,
      supportsHtmlBody: defaults.supportsHtmlBody,
      supportsAttachments: defaults.supportsAttachments,
    );
  }
}
