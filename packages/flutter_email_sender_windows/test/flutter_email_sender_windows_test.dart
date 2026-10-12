import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:flutter_email_sender_platform_interface/flutter_email_sender_platform_interface.dart';
import 'package:flutter_email_sender_windows/flutter_email_sender_windows.dart';
import 'package:flutter_email_sender_windows/src/mapi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

void main() {
  late Directory files;
  late List<MapiMail> sent;
  late int mapiResult;

  setUp(() async {
    files = await Directory.systemTemp.createTemp('windows_email_files_');
    sent = [];
    mapiResult = 0;
  });

  tearDown(() async {
    await files.delete(recursive: true);
  });

  FlutterEmailSenderWindows plugin({bool hasMapiClient = true}) =>
      FlutterEmailSenderWindows(
        hasMapiClient: () => hasMapiClient,
        sendMapiMail: (mail) async {
          sent.add(mail);
          return mapiResult;
        },
      );

  test('registerWith sets the platform instance', () {
    FlutterEmailSenderWindows.registerWith();

    expect(
      FlutterEmailSenderPlatform.instance,
      isA<FlutterEmailSenderWindows>(),
    );
  });

  test('getCapabilities supports attachments with a MAPI client', () async {
    final capabilities = await plugin().getCapabilities();

    expect(capabilities.canSend, isTrue);
    expect(capabilities.supportsAttachments, isTrue);
    expect(capabilities.supportsCc, isTrue);
    expect(capabilities.supportsBcc, isTrue);
    expect(capabilities.supportsHtmlBody, isFalse);
  });

  test('getCapabilities falls back to mailto: without a MAPI client', () async {
    final capabilities = await plugin(hasMapiClient: false).getCapabilities();

    expect(capabilities.canSend, isTrue);
    expect(capabilities.supportsAttachments, isFalse);
    expect(capabilities.supportsCc, isTrue);
  });

  test('send passes the email to the MAPI client', () async {
    final result = await plugin().sendWithResult(
      const Email(
        recipients: ['a@example.com', 'b@example.com'],
        cc: ['c@example.com'],
        bcc: ['d@example.com'],
        subject: 'Hello Wörld',
        body: 'Line 1\nLine 2',
      ),
    );

    expect(result, EmailSendResult.unknown);
    final mail = sent.single;
    expect(mail.to, ['a@example.com', 'b@example.com']);
    expect(mail.cc, ['c@example.com']);
    expect(mail.bcc, ['d@example.com']);
    expect(mail.subject, 'Hello Wörld');
    expect(mail.body, 'Line 1\nLine 2');
    expect(mail.attachments, isEmpty);
  });

  test('send attaches files and in-memory data in order', () async {
    final report = File('${files.path}/report.pdf')..writeAsStringSync('pdf');
    final photo = File('${files.path}/photo.jpg')..writeAsStringSync('jpg');

    await plugin().send(
      Email(
        attachmentPaths: [report.path],
        attachments: [
          EmailAttachment.data(
            Uint8List.fromList(utf8.encode('a,b')),
            fileName: r'..\export.csv',
          ),
          EmailAttachment.file(photo.path),
          EmailAttachment.data(Uint8List(0), fileName: '..'),
        ],
      ),
    );

    final attachments = sent.single.attachments;
    expect(attachments.map((attachment) => attachment.name), [
      'report.pdf',
      'export.csv',
      'photo.jpg',
      'attachment',
    ]);
    expect(attachments[0].path, report.absolute.path);
    expect(attachments[2].path, photo.absolute.path);
    expect(File(attachments[1].path).readAsStringSync(), 'a,b');
    final dataDirectory = File(attachments[1].path).parent.parent;
    expect(File(attachments[3].path).parent.parent.path, dataDirectory.path);
    await dataDirectory.delete(recursive: true);
  });

  test('send passes relative attachment paths as absolute paths', () async {
    final previous = Directory.current;
    Directory.current = files;
    addTearDown(() => Directory.current = previous);
    File('${files.path}/notes.txt').writeAsStringSync('notes');

    await plugin().send(const Email(attachmentPaths: ['notes.txt']));

    final path = sent.single.attachments.single.path;
    expect(File(path).isAbsolute, isTrue);
    expect(File(path).readAsStringSync(), 'notes');
  });

  test('send rejects an attachment that cannot be read', () async {
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
    expect(sent, isEmpty);
  });

  test('send rejects an HTML body', () async {
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
    expect(sent, isEmpty);
  });

  test('send maps MAPI result codes', () async {
    for (final (code, errorCode) in [
      (0, null),
      (mapiUserAbort, null),
      (mapiLoginFailure, 'not_available'),
      (2, 'error'),
      (11, 'error'),
    ]) {
      mapiResult = code;
      final sending = plugin().send(const Email(recipients: ['a@example.com']));

      if (errorCode == null) {
        await expectLater(sending, completes, reason: 'MAPI result $code');
      } else {
        await expectLater(
          sending,
          throwsA(
            isA<PlatformException>().having(
              (error) => error.code,
              'code',
              errorCode,
            ),
          ),
          reason: 'MAPI result $code',
        );
      }
    }
  });

  group('without a MAPI client', () {
    late _FakeUrlLauncher urlLauncher;

    setUp(() {
      urlLauncher = _FakeUrlLauncher();
      UrlLauncherPlatform.instance = urlLauncher;
    });

    test('send opens a mailto: link', () async {
      await plugin(
        hasMapiClient: false,
      ).send(const Email(recipients: ['a@example.com'], subject: 'Hi'));

      expect(urlLauncher.launched, ['mailto:a@example.com?subject=Hi']);
      expect(sent, isEmpty);
    });

    test('send rejects attachments', () async {
      await expectLater(
        plugin(hasMapiClient: false).send(
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
          plugin(
            hasMapiClient: false,
          ).send(const Email(recipients: ['a@example.com'])),
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

  group('MapiMessageW', () {
    test('matches the 64-bit layout of mapi.h', () {
      expect(sizeOf<MapiMessageW>(), 96);
      expect(sizeOf<MapiRecipDescW>(), 40);
      expect(sizeOf<MapiFileDescW>(), 40);
    });

    test('carries recipients, text and attachments', () {
      using((arena) {
        final message = allocateMapiMessage(
          const MapiMail(
            subject: 'Hello Wörld',
            body: 'Body',
            to: ['a@example.com'],
            cc: ['c@example.com'],
            bcc: ['d@example.com'],
            attachments: [(path: r'C:\files\report.pdf', name: 'report.pdf')],
          ),
          arena,
        ).ref;

        expect(message.lpszSubject.toDartString(), 'Hello Wörld');
        expect(message.lpszNoteText.toDartString(), 'Body');
        expect(message.nRecipCount, 3);
        final recipients = [
          for (var index = 0; index < message.nRecipCount; index++)
            message.lpRecips[index],
        ];
        expect(recipients.map((recipient) => recipient.ulRecipClass), [
          1,
          2,
          3,
        ]);
        expect(
          recipients.map((recipient) => recipient.lpszName.toDartString()),
          ['a@example.com', 'c@example.com', 'd@example.com'],
        );
        expect(
          recipients.map((recipient) => recipient.lpszAddress.toDartString()),
          ['SMTP:a@example.com', 'SMTP:c@example.com', 'SMTP:d@example.com'],
        );
        expect(message.nFileCount, 1);
        final file = message.lpFiles.ref;
        expect(file.lpszPathName.toDartString(), r'C:\files\report.pdf');
        expect(file.lpszFileName.toDartString(), 'report.pdf');
        expect(file.nPosition, 0xFFFFFFFF);
      });
    });

    test('leaves empty fields null', () {
      using((arena) {
        final message = allocateMapiMessage(
          const MapiMail(subject: '', body: ''),
          arena,
        ).ref;

        expect(message.lpszSubject, nullptr);
        expect(message.lpszNoteText, nullptr);
        expect(message.nRecipCount, 0);
        expect(message.lpRecips, nullptr);
        expect(message.nFileCount, 0);
        expect(message.lpFiles, nullptr);
      });
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
