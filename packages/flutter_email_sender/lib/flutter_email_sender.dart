import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_email_sender_platform_interface/flutter_email_sender_platform_interface.dart';

import 'src/exceptions.dart';

/// Flutter API for composing emails with the platform's native mail UI.
///
/// This library exports the [Email] request model, [EmailCapabilities] for
/// feature detection, and typed exceptions for expected failures.
export 'package:flutter_email_sender_platform_interface/flutter_email_sender_platform_interface.dart'
    show Email, EmailCapabilities;
export 'src/exceptions.dart';

/// Entry point for sending email through the current platform implementation.
class FlutterEmailSender {
  static FlutterEmailSenderPlatform get _platform =>
      FlutterEmailSenderPlatform.instance;

  /// Opens the platform email composer prefilled with [mail].
  ///
  /// Throws [FlutterEmailSenderNotAvailableException] when no email composer is
  /// available, [FlutterEmailSenderUnsupportedFeatureException] when the
  /// current platform cannot handle some requested fields, or
  /// [FlutterEmailSenderPlatformException] for other plugin errors.
  static Future<void> send(Email mail) async {
    try {
      await _platform.send(mail);
    } on PlatformException catch (error) {
      throw _mapPlatformException(error);
    }
  }

  /// Returns the current platform's email support and feature availability.
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
