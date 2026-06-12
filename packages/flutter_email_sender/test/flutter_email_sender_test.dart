import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter_email_sender_platform_interface/flutter_email_sender_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakeFlutterEmailSenderPlatform extends FlutterEmailSenderPlatform
    with MockPlatformInterfaceMixin {
  Email? sentEmail;

  @override
  Future<EmailCapabilities> getCapabilities() async {
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
}
