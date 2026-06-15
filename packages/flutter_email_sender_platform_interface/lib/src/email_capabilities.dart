import 'package:flutter/services.dart';

import 'email.dart';

/// Describes which email features are available on the current platform.
class EmailCapabilities {
  /// Creates a capability set for a platform implementation.
  const EmailCapabilities({
    required this.canSend,
    required this.supportsCc,
    required this.supportsBcc,
    required this.supportsSubject,
    required this.supportsPlainTextBody,
    required this.supportsHtmlBody,
    required this.supportsAttachments,
  });

  /// Creates a capability set for platforms with no available email support.
  const EmailCapabilities.none()
    : canSend = false,
      supportsCc = false,
      supportsBcc = false,
      supportsSubject = false,
      supportsPlainTextBody = false,
      supportsHtmlBody = false,
      supportsAttachments = false;

  /// Whether an email composer is currently available to the user.
  final bool canSend;

  /// Whether the platform supports `cc` recipients.
  final bool supportsCc;

  /// Whether the platform supports `bcc` recipients.
  final bool supportsBcc;

  /// Whether the platform supports the subject field.
  final bool supportsSubject;

  /// Whether the platform supports plain text body content.
  final bool supportsPlainTextBody;

  /// Whether the platform supports HTML body content.
  final bool supportsHtmlBody;

  /// Whether the platform supports file attachments.
  final bool supportsAttachments;

  /// Returns feature names required by [email] but unsupported on this platform.
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

  /// Throws a [PlatformException] when [email] cannot be sent on this platform.
  void validateEmail(Email email, {required String platformName}) {
    if (!canSend) {
      throw PlatformException(
        code: 'not_available',
        message: 'Email composer is unavailable on $platformName.',
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
