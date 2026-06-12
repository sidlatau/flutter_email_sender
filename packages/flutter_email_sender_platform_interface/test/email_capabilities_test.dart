import 'package:flutter/services.dart';
import 'package:flutter_email_sender_platform_interface/flutter_email_sender_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('validateEmail throws not_available when email cannot be sent', () {
    const capabilities = EmailCapabilities(
      canSend: false,
      supportsCc: true,
      supportsBcc: true,
      supportsSubject: true,
      supportsPlainTextBody: true,
      supportsHtmlBody: true,
      supportsAttachments: true,
    );

    expect(
      () => capabilities.validateEmail(
        const Email(recipients: <String>['to@example.com']),
        platformName: 'ios',
      ),
      throwsA(
        isA<PlatformException>()
            .having((error) => error.code, 'code', 'not_available')
            .having(
              (error) => error.message,
              'message',
              'Email composer is unavailable on ios.',
            ),
      ),
    );
  });

  test('validateEmail throws unsupported fields', () {
    const capabilities = EmailCapabilities(
      canSend: true,
      supportsCc: false,
      supportsBcc: false,
      supportsSubject: true,
      supportsPlainTextBody: true,
      supportsHtmlBody: false,
      supportsAttachments: false,
    );

    expect(
      () => capabilities.validateEmail(
        const Email(
          cc: <String>['cc@example.com'],
          attachmentPaths: <String>['/tmp/file.txt'],
          isHTML: true,
          body: '<b>Hello</b>',
        ),
        platformName: 'web',
      ),
      throwsA(
        isA<PlatformException>().having(
          (error) => error.code,
          'code',
          'unsupported',
        ),
      ),
    );
  });
}
