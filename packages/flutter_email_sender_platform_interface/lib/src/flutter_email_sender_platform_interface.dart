import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'email.dart';
import 'email_capabilities.dart';

/// Abstract platform contract for federated `flutter_email_sender` backends.
abstract class FlutterEmailSenderPlatform extends PlatformInterface {
  /// Creates a platform interface instance for an implementation.
  FlutterEmailSenderPlatform() : super(token: _token);

  static final Object _token = Object();
  static final FlutterEmailSenderPlatform _defaultInstance =
      _DefaultFlutterEmailSenderPlatform();

  /// The active platform implementation used by the public package API.
  static FlutterEmailSenderPlatform _instance = _defaultInstance;

  /// Registered platform implementation.
  static FlutterEmailSenderPlatform get instance => _instance;

  /// Registers the active platform implementation.
  static set instance(FlutterEmailSenderPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Sends the provided [email] using the platform implementation.
  Future<void> send(Email email);

  /// Reports the current platform's email capabilities.
  Future<EmailCapabilities> getCapabilities();
}

class _DefaultFlutterEmailSenderPlatform extends FlutterEmailSenderPlatform {
  @override
  Future<void> send(Email email) {
    throw UnimplementedError('send() has not been implemented.');
  }

  @override
  Future<EmailCapabilities> getCapabilities() async {
    return const EmailCapabilities.none();
  }
}
