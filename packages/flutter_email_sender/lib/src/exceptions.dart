import 'package:flutter/services.dart';

/// Base class for typed exceptions thrown by `flutter_email_sender`.
sealed class FlutterEmailSenderException implements Exception {
  /// Creates a package-specific exception with a human-readable [message].
  const FlutterEmailSenderException(this.message);

  /// Description of the failure returned by the platform implementation.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when no native email composer is currently available.
final class FlutterEmailSenderNotAvailableException
    extends FlutterEmailSenderException {
  /// Creates an exception for an unavailable email composer.
  const FlutterEmailSenderNotAvailableException([
    super.message = 'Email composer is unavailable.',
  ]);
}

/// Thrown when the current platform cannot support requested email features.
final class FlutterEmailSenderUnsupportedFeatureException
    extends FlutterEmailSenderException {
  /// Creates an exception that lists the unsupported email features.
  const FlutterEmailSenderUnsupportedFeatureException({
    required this.unsupportedFeatures,
    required String message,
  }) : super(message);

  /// Requested features that are unsupported on the current platform.
  final List<String> unsupportedFeatures;
}

/// Thrown for unexpected platform or plugin errors.
final class FlutterEmailSenderPlatformException
    extends FlutterEmailSenderException {
  /// Creates an exception from a platform error payload.
  const FlutterEmailSenderPlatformException({
    required this.code,
    required String message,
    this.details,
  }) : super(message);

  /// Creates a package exception from a raw [PlatformException].
  factory FlutterEmailSenderPlatformException.fromPlatformException(
    PlatformException exception,
  ) {
    return FlutterEmailSenderPlatformException(
      code: exception.code,
      message: exception.message ?? 'Unknown platform error.',
      details: exception.details,
    );
  }

  /// Platform-specific error code.
  final String code;

  /// Optional platform-specific error details.
  final Object? details;
}
