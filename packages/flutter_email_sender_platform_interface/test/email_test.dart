import 'package:flutter_email_sender_platform_interface/flutter_email_sender_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toMailtoUri encodes recipients, subject, cc, bcc and body', () {
    const email = Email(
      recipients: <String>['to@example.com', 'second+tag@example.com'],
      cc: <String>['cc@example.com'],
      bcc: <String>['bcc@example.com'],
      subject: 'Q&A = fun?',
      body: 'Line 1\nLine 2 & more',
    );

    final uri = email.toMailtoUri();

    expect(uri.scheme, 'mailto');
    expect(uri.path, 'to@example.com,second+tag@example.com');
    expect(uri.queryParameters, <String, String>{
      'subject': 'Q&A = fun?',
      'cc': 'cc@example.com',
      'bcc': 'bcc@example.com',
      'body': 'Line 1\nLine 2 & more',
    });
  });

  test('toMailtoUri leaves out empty fields', () {
    expect(const Email().toMailtoUri().toString(), 'mailto:');
  });
}
