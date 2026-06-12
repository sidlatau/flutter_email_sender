import 'package:flutter/services.dart';

sealed class FlutterEmailSenderException implements Exception {
  const FlutterEmailSenderException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class FlutterEmailSenderNotAvailableException
    extends FlutterEmailSenderException {
  const FlutterEmailSenderNotAvailableException([
    super.message = 'Email composer is unavailable.',
  ]);
}

final class FlutterEmailSenderUnsupportedFeatureException
    extends FlutterEmailSenderException {
  const FlutterEmailSenderUnsupportedFeatureException({
    required this.unsupportedFeatures,
    required String message,
  }) : super(message);

  final List<String> unsupportedFeatures;
}

final class FlutterEmailSenderPlatformException
    extends FlutterEmailSenderException {
  const FlutterEmailSenderPlatformException({
    required this.code,
    required String message,
    this.details,
  }) : super(message);

  factory FlutterEmailSenderPlatformException.fromPlatformException(
    PlatformException exception,
  ) {
    return FlutterEmailSenderPlatformException(
      code: exception.code,
      message: exception.message ?? 'Unknown platform error.',
      details: exception.details,
    );
  }

  final String code;
  final Object? details;
}
