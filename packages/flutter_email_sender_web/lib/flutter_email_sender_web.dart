import 'package:flutter_email_sender_platform_interface/flutter_email_sender_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:url_launcher/url_launcher.dart';

class FlutterEmailSenderWeb extends FlutterEmailSenderPlatform {
  static void registerWith(Registrar registrar) {
    FlutterEmailSenderPlatform.instance = FlutterEmailSenderWeb();
  }

  static const EmailCapabilities _capabilities = EmailCapabilities.mailto(
    canSend: true,
  );

  @override
  Future<void> send(Email email) async {
    _capabilities.validateEmail(email, platformName: 'web');

    final didLaunch = await launchUrl(
      email.toMailtoUri(),
      webOnlyWindowName: '_self',
    );

    if (!didLaunch) {
      throw PlatformException(
        code: 'not_available',
        message: 'Could not launch email composer.',
      );
    }
  }

  @override
  Future<EmailCapabilities> getCapabilities() async => _capabilities;
}
