import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter/services.dart';
import 'package:flutter_email_sender_platform_interface/flutter_email_sender_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakeFlutterEmailSenderPlatform extends FlutterEmailSenderPlatform
    with MockPlatformInterfaceMixin {
  Email? sentEmail;
  Object? sendError;
  Object? capabilitiesError;

  @override
  Future<EmailCapabilities> getCapabilities() async {
    if (capabilitiesError case final Object error) {
      throw error;
    }

    return const EmailCapabilities(
      canSend: true,
      supportsCc: true,
      supportsBcc: true,
      supportsSubject: true,
      supportsPlainTextBody: true,
      supportsHtmlBody: false,
      supportsAttachments: false,
    );
  }

  @override
  Future<void> send(Email email) async {
    if (sendError case final Object error) {
      throw error;
    }

    sentEmail = email;
  }
}

void main() {
  late FlutterEmailSenderPlatform originalPlatform;
  late _FakeFlutterEmailSenderPlatform fakePlatform;

  setUp(() {
    originalPlatform = FlutterEmailSenderPlatform.instance;
    fakePlatform = _FakeFlutterEmailSenderPlatform();
    FlutterEmailSenderPlatform.instance = fakePlatform;
  });

  tearDown(() {
    FlutterEmailSenderPlatform.instance = originalPlatform;
  });

  test('send delegates to the platform implementation', () async {
    const email = Email(
      subject: 'subject',
      recipients: <String>['to@example.com'],
    );

    await FlutterEmailSender.send(email);

    expect(fakePlatform.sentEmail, same(email));
  });

  test('getCapabilities delegates to the platform implementation', () async {
    final capabilities = await FlutterEmailSender.getCapabilities();

    expect(capabilities.canSend, isTrue);
    expect(capabilities.supportsAttachments, isFalse);
  });

  test('send maps not_available to typed exception', () async {
    fakePlatform.sendError = PlatformException(
      code: 'not_available',
      message: 'Email composer is unavailable on ios.',
    );

    await expectLater(
      () => FlutterEmailSender.send(const Email()),
      throwsA(isA<FlutterEmailSenderNotAvailableException>()),
    );
  });

  test('send maps unsupported to typed exception', () async {
    fakePlatform.sendError = PlatformException(
      code: 'unsupported',
      message: 'The current platform does not support: attachments, HTML body.',
    );

    await expectLater(
      () => FlutterEmailSender.send(const Email()),
      throwsA(
        isA<FlutterEmailSenderUnsupportedFeatureException>().having(
          (error) => error.unsupportedFeatures,
          'unsupportedFeatures',
          <String>['attachments', 'HTML body'],
        ),
      ),
    );
  });

  test('getCapabilities maps unknown platform errors', () async {
    fakePlatform.capabilitiesError = PlatformException(
      code: 'boom',
      message: 'Unexpected platform error.',
    );

    await expectLater(
      FlutterEmailSender.getCapabilities,
      throwsA(
        isA<FlutterEmailSenderPlatformException>().having(
          (error) => error.code,
          'code',
          'boom',
        ),
      ),
    );
  });
}
