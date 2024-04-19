import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

class FlutterEmailSender {
  static const MethodChannel _channel =
      const MethodChannel('flutter_email_sender');

  static Future<void> send(Email mail) {
    return _channel.invokeMethod('send', mail.toJson());
  }

  static Future<bool> canSend() async {
    if (Platform.isIOS) {
      return await _channel.invokeMethod('canSend');
    }

    return true;
  }
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

extension EmailExt on Email {
  Future<void> send() {
    return FlutterEmailSender.send(this);
  }
}
