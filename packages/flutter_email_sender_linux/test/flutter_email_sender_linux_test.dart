@TestOn('linux || mac-os')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_email_sender_linux/flutter_email_sender_linux.dart';
import 'package:flutter_email_sender_platform_interface/flutter_email_sender_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

void main() {
  late Directory bin;
  late Directory files;

  setUp(() async {
    bin = await Directory.systemTemp.createTemp('xdg_email_bin_');
    files = await Directory.systemTemp.createTemp('xdg_email_files_');
  });

  tearDown(() async {
    await bin.delete(recursive: true);
    await files.delete(recursive: true);
  });

  FlutterEmailSenderLinux plugin({
    Duration launchTimeout = const Duration(seconds: 2),
  }) => FlutterEmailSenderLinux(
    environment: {'PATH': '/nonexistent:${bin.path}'},
    launchTimeout: launchTimeout,
  );

  void installXdgEmail({int exitCode = 0, String before = ''}) {
    final script = File('${bin.path}/xdg-email')
      ..writeAsStringSync(
        '#!/bin/sh\n'
        r'printf "%s\0" "$@" > "$(dirname "$0")/arguments"'
        '\n$before\nexit $exitCode\n',
      );
    Process.runSync('chmod', ['755', script.path]);
  }

  List<String> xdgEmailArguments() {
    final file = File('${bin.path}/arguments');
    if (!file.existsSync()) {
      return const [];
    }
    return file.readAsStringSync().split('\u0000')..removeLast();
  }

  test('registerWith sets the platform instance', () {
    FlutterEmailSenderLinux.registerWith();

    expect(FlutterEmailSenderPlatform.instance, isA<FlutterEmailSenderLinux>());
  });

  test('getCapabilities supports attachments with xdg-email', () async {
    installXdgEmail();

    final capabilities = await plugin().getCapabilities();

    expect(capabilities.canSend, isTrue);
    expect(capabilities.supportsAttachments, isTrue);
    expect(capabilities.supportsCc, isTrue);
    expect(capabilities.supportsBcc, isTrue);
    expect(capabilities.supportsHtmlBody, isFalse);
  });

  test('getCapabilities falls back to mailto: without xdg-email', () async {
    File('${bin.path}/xdg-email').writeAsStringSync('not executable');

    final capabilities = await plugin().getCapabilities();

    expect(capabilities.canSend, isTrue);
    expect(capabilities.supportsAttachments, isFalse);
    expect(capabilities.supportsCc, isTrue);
  });

  test('send passes the email to xdg-email as a mailto: URI', () async {
    installXdgEmail();

    final result = await plugin().sendWithResult(
      const Email(
        recipients: ['a@example.com', 'b@example.com'],
        cc: ['c@example.com'],
        bcc: ['d@example.com'],
        subject: 'Hello Wörld, & more',
        body: "Line 1\nLine 2 C:\\new 'q'",
      ),
    );

    expect(result, EmailSendResult.unknown);
    expect(xdgEmailArguments(), [
      '--utf8',
      'mailto:a@example.com,b@example.com'
          '?subject=Hello%20W%C3%B6rld%2C%20%26%20more'
          '&cc=c%40example.com&bcc=d%40example.com'
          "&body=Line%201%0ALine%202%20C%3A%5Cnew%20'q'",
    ]);
  });

  test('send attaches files and in-memory data in order', () async {
    installXdgEmail();
    final report = File('${files.path}/report.pdf')..writeAsStringSync('pdf');
    final photo = File('${files.path}/photo.jpg')..writeAsStringSync('jpg');

    await plugin().send(
      Email(
        attachmentPaths: [report.path],
        attachments: [
          EmailAttachment.data(
            Uint8List.fromList(utf8.encode('a,b')),
            fileName: '../export.csv',
          ),
          EmailAttachment.file(photo.path),
          EmailAttachment.data(Uint8List(0), fileName: '..'),
        ],
      ),
    );

    final arguments = xdgEmailArguments();
    expect(arguments, [
      '--utf8',
      '--attach',
      report.path,
      '--attach',
      endsWith('/1/export.csv'),
      '--attach',
      photo.path,
      '--attach',
      endsWith('/3/attachment'),
      'mailto:',
    ]);
    final dataDirectory = File(arguments[4]).parent.parent;
    expect(dataDirectory.statSync().modeString(), 'rwx------');
    expect(File(arguments[4]).readAsStringSync(), 'a,b');
    expect(File(arguments[8]).parent.parent.path, dataDirectory.path);
    await dataDirectory.delete(recursive: true);
  });

  test('send rejects an attachment that cannot be read', () async {
    installXdgEmail();

    for (final path in ['${files.path}/missing.txt', files.path]) {
      await expectLater(
        plugin().send(Email(attachmentPaths: [path])),
        throwsA(
          isA<PlatformException>()
              .having((error) => error.code, 'code', 'error')
              .having(
                (error) => error.message,
                'message',
                '$path: The attachment file cannot be read.',
              ),
        ),
      );
    }
    expect(xdgEmailArguments(), isEmpty);
  });

  test('send rejects an HTML body', () async {
    installXdgEmail();

    await expectLater(
      plugin().send(const Email(body: '<b>Hi</b>', isHTML: true)),
      throwsA(
        isA<PlatformException>().having(
          (error) => error.code,
          'code',
          'unsupported',
        ),
      ),
    );
  });

  test('send maps xdg-email exit codes', () async {
    for (final (exitCode, errorCode) in [
      (1, 'error'),
      (2, 'error'),
      (3, 'not_available'),
      (4, 'not_available'),
      (5, 'error'),
    ]) {
      installXdgEmail(exitCode: exitCode);

      await expectLater(
        plugin().send(const Email(recipients: ['a@example.com'])),
        throwsA(
          isA<PlatformException>().having(
            (error) => error.code,
            'code',
            errorCode,
          ),
        ),
        reason: 'exit code $exitCode',
      );
    }
  });

  test('send returns while xdg-email waits for the mail client', () async {
    installXdgEmail(before: 'sleep 3', exitCode: 4);
    final stopwatch = Stopwatch()..start();

    await plugin(
      launchTimeout: const Duration(milliseconds: 200),
    ).send(const Email(recipients: ['a@example.com']));

    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
  });

  group('without xdg-email', () {
    late _FakeUrlLauncher urlLauncher;

    setUp(() {
      urlLauncher = _FakeUrlLauncher();
      UrlLauncherPlatform.instance = urlLauncher;
    });

    test('send opens a mailto: link', () async {
      await plugin().send(
        const Email(recipients: ['a@example.com'], subject: 'Hi'),
      );

      expect(urlLauncher.launched, ['mailto:a@example.com?subject=Hi']);
    });

    test('send rejects attachments', () async {
      await expectLater(
        plugin().send(
          Email(
            attachments: [
              EmailAttachment.data(Uint8List(1), fileName: 'a.bin'),
            ],
          ),
        ),
        throwsA(
          isA<PlatformException>().having(
            (error) => error.code,
            'code',
            'unsupported',
          ),
        ),
      );
      expect(urlLauncher.launched, isEmpty);
    });

    test('send reports a mailto: link that cannot be opened', () async {
      for (final failure in [
        () async => false,
        () async => throw PlatformException(code: 'Launch Error'),
      ]) {
        urlLauncher.result = failure;

        await expectLater(
          plugin().send(const Email(recipients: ['a@example.com'])),
          throwsA(
            isA<PlatformException>().having(
              (error) => error.code,
              'code',
              'not_available',
            ),
          ),
        );
      }
    });
  });
}

class _FakeUrlLauncher extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  final launched = <String>[];
  Future<bool> Function() result = () async => true;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) {
    launched.add(url);
    return result();
  }
}
