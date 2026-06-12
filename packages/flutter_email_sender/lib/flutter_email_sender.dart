import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_email_sender_platform_interface/flutter_email_sender_platform_interface.dart';

import 'src/exceptions.dart';

export 'package:flutter_email_sender_platform_interface/flutter_email_sender_platform_interface.dart'
    show Email, EmailCapabilities;
export 'src/exceptions.dart';

class FlutterEmailSender {
  static FlutterEmailSenderPlatform get _platform =>
      FlutterEmailSenderPlatform.instance;

  static Future<void> send(Email mail) async {
    try {
      await _platform.send(mail);
    } on PlatformException catch (error) {
      throw _mapPlatformException(error);
    }
  }

  static Future<EmailCapabilities> getCapabilities() async {
    try {
      return await _platform.getCapabilities();
    } on PlatformException catch (error) {
      throw _mapPlatformException(error);
    }
  }

  static FlutterEmailSenderException _mapPlatformException(
    PlatformException error,
  ) {
    switch (error.code) {
      case 'not_available':
        return FlutterEmailSenderNotAvailableException(
          error.message ?? 'Email composer is unavailable.',
        );
      case 'unsupported':
        return FlutterEmailSenderUnsupportedFeatureException(
          unsupportedFeatures: _extractUnsupportedFeatures(error.message),
          message:
              error.message ?? 'The current platform does not support this email request.',
        );
      default:
        return FlutterEmailSenderPlatformException.fromPlatformException(error);
    }
  }

  static List<String> _extractUnsupportedFeatures(String? message) {
    if (message == null) {
      return const [];
    }

    const prefix = 'The current platform does not support: ';
    if (!message.startsWith(prefix)) {
      return const [];
    }

    return message
        .substring(prefix.length)
        .split(',')
        .map((feature) => feature.trim().replaceFirst(RegExp(r'\.+$'), ''))
        .where((feature) => feature.isNotEmpty)
        .toList(growable: false);
  }
}
