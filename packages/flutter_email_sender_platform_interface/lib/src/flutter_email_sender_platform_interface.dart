import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'email.dart';
import 'email_capabilities.dart';

abstract class FlutterEmailSenderPlatform extends PlatformInterface {
  FlutterEmailSenderPlatform() : super(token: _token);

  static final Object _token = Object();
  static final FlutterEmailSenderPlatform _defaultInstance =
      _DefaultFlutterEmailSenderPlatform();

  static FlutterEmailSenderPlatform _instance = _defaultInstance;

  static FlutterEmailSenderPlatform get instance => _instance;

  static set instance(FlutterEmailSenderPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  static bool get usesDefaultInstance => identical(_instance, _defaultInstance);

  Future<void> send(Email email);

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
