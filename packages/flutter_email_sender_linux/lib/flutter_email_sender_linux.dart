import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_email_sender_platform_interface/flutter_email_sender_platform_interface.dart';
import 'package:url_launcher/url_launcher.dart';

/// Linux implementation of `flutter_email_sender`.
///
/// Opens the default mail client with `xdg-email`, or with a `mailto:` link
/// when `xdg-email` is not installed.
class FlutterEmailSenderLinux extends FlutterEmailSenderPlatform {
  /// Creates the Linux implementation.
  FlutterEmailSenderLinux({
    @visibleForTesting Map<String, String>? environment,
    @visibleForTesting Duration launchTimeout = const Duration(seconds: 2),
  }) : _environment = environment ?? Platform.environment,
       _launchTimeout = launchTimeout;

  /// Registers this class as the default [FlutterEmailSenderPlatform].
  static void registerWith() {
    FlutterEmailSenderPlatform.instance = FlutterEmailSenderLinux();
  }

  static const EmailCapabilities _xdgEmailCapabilities = EmailCapabilities(
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

  static const int _anyExecuteBit = 0x49;

  final Map<String, String> _environment;
  final Duration _launchTimeout;

  @override
  Future<EmailCapabilities> getCapabilities() async =>
      _findXdgEmail() == null ? _mailtoCapabilities : _xdgEmailCapabilities;

  @override
  Future<void> send(Email email) async {
    final xdgEmail = _findXdgEmail();
    if (xdgEmail == null) {
      _mailtoCapabilities.validateEmail(email, platformName: 'linux');
      await _openMailto(email);
      return;
    }

    _xdgEmailCapabilities.validateEmail(email, platformName: 'linux');
    final attachmentPaths = await _attachmentPaths(email);

    final Process process;
    try {
      process = await Process.start(xdgEmail, [
        '--utf8',
        for (final path in attachmentPaths) ...['--attach', path],
        email.toMailtoUri().toString(),
      ], mode: ProcessStartMode.inheritStdio);
    } on ProcessException catch (error) {
      throw PlatformException(code: 'not_available', message: error.message);
    }

    // xdg-email usually runs a mail client that is not running yet in the
    // foreground, so it only exits once the user quits that client.
    final exitCode = await process.exitCode.timeout(
      _launchTimeout,
      onTimeout: () => 0,
    );
    switch (exitCode) {
      case 0:
        return;
      case 3 || 4:
        throw PlatformException(
          code: 'not_available',
          message: 'xdg-email could not open a mail client.',
        );
      default:
        throw PlatformException(
          code: 'error',
          message: 'xdg-email failed with exit code $exitCode.',
        );
    }
  }

  String? _findXdgEmail() {
    for (final directory in (_environment['PATH'] ?? '').split(':')) {
      if (directory.isEmpty) {
        continue;
      }
      final candidate = '$directory/xdg-email';
      final stat = FileStat.statSync(candidate);
      if (stat.type == FileSystemEntityType.file &&
          stat.mode & _anyExecuteBit != 0) {
        return candidate;
      }
    }
    return null;
  }

  Future<List<String>> _attachmentPaths(Email email) async {
    final paths = <String>[];
    Directory? dataDirectory;
    for (final attachment in [
      ...?email.attachmentPaths?.map(EmailAttachment.file),
      ...email.attachments,
    ]) {
      if (attachment.data case final data?) {
        dataDirectory ??= await _createPrivateTempDirectory();
        final file = File(
          '${dataDirectory.path}/${paths.length}/'
          '${_baseName(attachment.fileName!)}',
        );
        await file.create(recursive: true);
        await file.writeAsBytes(data);
        paths.add(file.path);
      } else {
        final path = attachment.path!;
        if (!await _canRead(path)) {
          throw PlatformException(
            code: 'error',
            message: '$path: The attachment file cannot be read.',
          );
        }
        paths.add(path);
      }
    }
    return paths;
  }

  static Future<Directory> _createPrivateTempDirectory() async {
    final directory = await Directory.systemTemp.createTemp(
      'flutter_email_sender_',
    );
    // createTemp applies the umask, which usually lets other users read it.
    final chmod = await Process.run('chmod', ['700', directory.path]);
    if (chmod.exitCode != 0) {
      await directory.delete();
      throw PlatformException(
        code: 'error',
        message: 'Could not restrict access to ${directory.path}.',
      );
    }
    return directory;
  }

  static String _baseName(String fileName) {
    final name = fileName.split('/').last;
    return name.isEmpty || name == '.' || name == '..' ? 'attachment' : name;
  }

  static Future<bool> _canRead(String path) async {
    try {
      await (await File(path).open()).close();
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
