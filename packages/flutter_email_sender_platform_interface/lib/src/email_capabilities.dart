import 'package:flutter/services.dart';

import 'email.dart';

class EmailCapabilities {
  const EmailCapabilities({
    required this.canSend,
    required this.supportsCc,
    required this.supportsBcc,
    required this.supportsSubject,
    required this.supportsPlainTextBody,
    required this.supportsHtmlBody,
    required this.supportsAttachments,
  });

  const EmailCapabilities.none()
    : canSend = false,
      supportsCc = false,
      supportsBcc = false,
      supportsSubject = false,
      supportsPlainTextBody = false,
      supportsHtmlBody = false,
      supportsAttachments = false;

  final bool canSend;
  final bool supportsCc;
  final bool supportsBcc;
  final bool supportsSubject;
  final bool supportsPlainTextBody;
  final bool supportsHtmlBody;
  final bool supportsAttachments;

  List<String> unsupportedFeaturesFor(Email email) {
    final unsupported = <String>[];

    if (!supportsCc && email.cc.isNotEmpty) {
      unsupported.add('cc');
    }
    if (!supportsBcc && email.bcc.isNotEmpty) {
      unsupported.add('bcc');
    }
    if (!supportsSubject && email.hasSubject) {
      unsupported.add('subject');
    }
    if (!supportsAttachments && email.hasAttachments) {
      unsupported.add('attachments');
    }
    if (email.hasBody) {
      if (email.isHTML) {
        if (!supportsHtmlBody) {
          unsupported.add('HTML body');
        }
      } else if (!supportsPlainTextBody) {
        unsupported.add('plain text body');
      }
    }

    return unsupported;
  }

  void validateEmail(Email email, {required String platformName}) {
    if (!canSend) {
      throw PlatformException(
        code: 'unsupported',
        message: 'flutter_email_sender is not supported on $platformName.',
      );
    }

    final unsupported = unsupportedFeaturesFor(email);
    if (unsupported.isEmpty) {
      return;
    }

    throw PlatformException(
      code: 'unsupported',
      message:
          'The current platform does not support: ${unsupported.join(', ')}.',
    );
  }
}
