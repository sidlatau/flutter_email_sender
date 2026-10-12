import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_email_sender_platform_interface/flutter_email_sender_platform_interface.dart';
import 'package:url_launcher/url_launcher.dart';

import 'src/mapi.dart';
import 'src/registry.dart';

/// Windows implementation of `flutter_email_sender`.
///
/// Opens the composer of the default mail client through Simple MAPI, which
/// classic Outlook and Thunderbird support, or a `mailto:` link for other mail
/// clients such as the new Outlook.
class FlutterEmailSenderWindows extends FlutterEmailSenderPlatform {
  /// Creates the Windows implementation.
  FlutterEmailSenderWindows({
    @visibleForTesting bool Function()? hasMapiClient,
    @visibleForTesting Future<int> Function(MapiMail mail)? sendMapiMail,
  }) : _hasMapiClient = hasMapiClient ?? hasDefaultMapiClient,
       _sendMapiMail = sendMapiMail ?? _sendMapiMailInBackground;

  /// Registers this class as the default [FlutterEmailSenderPlatform].
  static void registerWith() {
    FlutterEmailSenderPlatform.instance = FlutterEmailSenderWindows();
  }

  static const EmailCapabilities _mapiCapabilities = EmailCapabilities(
    canSend: true,
    supportsCc: true,
    supportsBcc: true,
    supportsSubject: true,
    supportsPlainTextBody: true,
    supportsHtmlBody: false,
    supportsAttachments: true,
  );

  static const EmailCapabilities _mailtoCapabilities = EmailCapabilities.mailto(
    canSend: true,
  );

  final bool Function() _hasMapiClient;
  final Future<int> Function(MapiMail mail) _sendMapiMail;

  @override
  Future<EmailCapabilities> getCapabilities() async =>
      _hasMapiClient() ? _mapiCapabilities : _mailtoCapabilities;

  @override
  Future<void> send(Email email) async {
    if (!_hasMapiClient()) {
      _mailtoCapabilities.validateEmail(email, platformName: 'windows');
      await _openMailto(email);
      return;
    }

    _mapiCapabilities.validateEmail(email, platformName: 'windows');
    final result = await _sendMapiMail(
      MapiMail(
        subject: email.subject,
        body: email.body,
        to: email.recipients,
        cc: email.cc,
        bcc: email.bcc,
        attachments: await _attachments(email),
      ),
    );
    switch (result) {
      case 0 || mapiUserAbort:
        return;
      case mapiLoginFailure:
        throw PlatformException(
          code: 'not_available',
          message: 'The mail client could not log on (MAPI error $result).',
        );
      default:
        throw PlatformException(
          code: 'error',
          message: 'MAPISendMailW failed with error $result.',
        );
    }
  }

  static Future<int> _sendMapiMailInBackground(MapiMail mail) =>
      Isolate.run(() => sendMapiMail(mail));

  static Future<List<({String path, String name})>> _attachments(
    Email email,
  ) async {
    final attachments = <({String path, String name})>[];
    Directory? dataDirectory;
    for (final attachment in [
      ...?email.attachmentPaths?.map(EmailAttachment.file),
      ...email.attachments,
    ]) {
      if (attachment.data case final data?) {
        dataDirectory ??= await Directory.systemTemp.createTemp(
          'flutter_email_sender_',
        );
        final name = _baseName(attachment.fileName!);
        final file = File(
          '${dataDirectory.path}${Platform.pathSeparator}${attachments.length}'
          '${Platform.pathSeparator}$name',
        );
        await file.create(recursive: true);
        await file.writeAsBytes(data);
        attachments.add((path: file.path, name: name));
      } else {
        // The mail client runs in another process with its own working
        // directory.
        final file = File(attachment.path!).absolute;
        if (!await _canRead(file)) {
          throw PlatformException(
            code: 'error',
            message: '${attachment.path}: The attachment file cannot be read.',
          );
        }
        attachments.add((path: file.path, name: _baseName(file.path)));
      }
    }
    return attachments;
  }

  static String _baseName(String fileName) {
    final name = fileName.split(RegExp(r'[/\\]')).last;
    return name.isEmpty || name == '.' || name == '..' ? 'attachment' : name;
  }

  static Future<bool> _canRead(File file) async {
    try {
      await (await file.open()).close();
      return true;
    } on FileSystemException {
      return false;
    }
  }

  static Future<void> _openMailto(Email email) async {
    try {
      if (await launchUrl(email.toMailtoUri())) {
        return;
      }
    } on PlatformException catch (error) {
      throw PlatformException(code: 'not_available', message: error.message);
    }
    throw PlatformException(
      code: 'not_available',
      message: 'Could not open the mailto: link.',
    );
  }
}
