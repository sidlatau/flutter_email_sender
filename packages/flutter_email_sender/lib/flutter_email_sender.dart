import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_email_sender_platform_interface/flutter_email_sender_platform_interface.dart';

import 'src/exceptions.dart';

/// Flutter API for composing emails with the platform's native mail UI.
///
/// This library exports the [Email] request model with [EmailAttachment],
/// [EmailCapabilities] for feature detection, [EmailSendResult], and typed
/// exceptions for expected failures.
export 'package:flutter_email_sender_platform_interface/flutter_email_sender_platform_interface.dart'
    show Email, EmailAttachment, EmailCapabilities, EmailSendResult;
export 'src/exceptions.dart';

/// Entry point for sending email through the current platform implementation.
class FlutterEmailSender {
  static FlutterEmailSenderPlatform get _platform =>
      FlutterEmailSenderPlatform.instance;

  /// Opens the platform email composer prefilled with [mail].
  ///
  /// On Android and iOS the returned future completes when the user leaves the
  /// composer; on macOS and web, once the composer has been opened. On iOS the
  /// result tells whether the email was sent, saved or discarded; other
  /// platforms return [EmailSendResult.unknown].
  ///
  /// Throws [FlutterEmailSenderNotAvailableException] when no email composer is
  /// available, [FlutterEmailSenderUnsupportedFeatureException] when the
  /// current platform cannot handle some requested fields, or
  /// [FlutterEmailSenderPlatformException] for other plugin errors, including
  /// an email that iOS failed to send.
  static Future<EmailSendResult> send(Email mail) async {
    try {
      return await _platform.sendWithResult(mail);
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
              error.message ??
              'The current platform does not support this email request.',
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
