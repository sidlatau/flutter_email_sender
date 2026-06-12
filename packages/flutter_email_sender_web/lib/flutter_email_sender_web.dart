import 'package:flutter_email_sender_platform_interface/flutter_email_sender_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:url_launcher/url_launcher.dart';

class FlutterEmailSenderWeb extends FlutterEmailSenderPlatform {
  static void registerWith(Registrar registrar) {
    FlutterEmailSenderPlatform.instance = FlutterEmailSenderWeb();
  }

  static const EmailCapabilities _capabilities = EmailCapabilities(
    isAvailable: true,
    supportsCc: true,
    supportsBcc: true,
    supportsSubject: true,
    supportsPlainTextBody: true,
    supportsHtmlBody: false,
    supportsAttachments: false,
  );

  @override
  Future<void> send(Email email) async {
    _capabilities.validateEmail(email, platformName: 'web');

    final queryParameters = <String, String>{
      if (email.hasSubject) 'subject': email.subject,
      if (email.cc.isNotEmpty) 'cc': email.cc.join(','),
      if (email.bcc.isNotEmpty) 'bcc': email.bcc.join(','),
      if (email.hasBody) 'body': email.body,
    };

    final emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email.recipients.join(','),
      query: _encodeQueryParameters(queryParameters),
    );

    final didLaunch = await launchUrl(
      emailLaunchUri,
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

String? _encodeQueryParameters(Map<String, String> params) {
  if (params.isEmpty) {
    return null;
  }

  return params.entries
      .map(
        (entry) =>
            '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}',
      )
      .join('&');
}
