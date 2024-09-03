import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class FlutterEmailSender {
  static const MethodChannel _channel =
      const MethodChannel('flutter_email_sender');

  static Future<void> send(Email mail) async {
    if (kIsWeb) {
      final Uri emailLaunchUri = Uri(
        scheme: 'mailto',
        path: mail.recipients.join(','),
        query: encodeQueryParameters(<String, String>{
          'subject': mail.subject,
          'cc': mail.cc.join(','),
          'bcc': mail.bcc.join(','),
          'body': mail.body,
        }),
      );

      await launchUrl(emailLaunchUri);
      return;
    }

    return _channel.invokeMethod('send', mail.toJson());
  }
}

String? encodeQueryParameters(Map<String, String> params) {
  return params.entries
      .map((MapEntry<String, String> e) =>
          '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');
}

class Email {
  final String subject;
  final List<String> recipients;
  final List<String> cc;
  final List<String> bcc;
  final String body;
  final List<String>? attachmentPaths;
  final bool isHTML;
  Email({
    this.subject = '',
    this.recipients = const [],
    this.cc = const [],
    this.bcc = const [],
    this.body = '',
    this.attachmentPaths,
    this.isHTML = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'body': body,
      'recipients': recipients,
      'cc': cc,
      'bcc': bcc,
      'attachment_paths': attachmentPaths,
      'is_html': isHTML
    };
  }
}
