import 'dart:async';
import 'package:flutter/services.dart';

enum EmailSendingStatus { clientNotAvailable, unknown, sent }

class FlutterEmailSender {
  static const MethodChannel _channel =
      const MethodChannel('flutter_email_sender');

  static Future<EmailSendingStatus> send(Email mail) async {
    try {
      await _channel.invokeMethod('send', mail.toJson());
      return EmailSendingStatus.sent;
    } catch (e) {
      if (e is PlatformException) {
        switch (e.code) {
          case "not_available":
            return EmailSendingStatus.clientNotAvailable;
            break;
          default:
            return EmailSendingStatus.unknown;
        }
      } else {
        return EmailSendingStatus.unknown;
      }
    }
  }
}

class Email {
  final String subject;
  final List<String> recipients;
  final List<String> cc;
  final List<String> bcc;
  final String body;
  final String attachmentPath;
  final bool isHTML;
  Email({
    this.subject = '',
    this.recipients = const [],
    this.cc = const [],
    this.bcc = const [],
    this.body = '',
    this.attachmentPath,
    this.isHTML = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'body': body,
      'recipients': recipients,
      'cc': cc,
      'bcc': bcc,
      'attachment_path': attachmentPath,
      'is_html': isHTML
    };
  }
}
