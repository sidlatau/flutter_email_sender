import 'package:flutter/services.dart';
import 'package:flutter_email_sender_platform_interface/flutter_email_sender_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('validateEmail throws unsupported fields', () {
    const capabilities = EmailCapabilities(
      isAvailable: true,
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
