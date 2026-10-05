import 'dart:typed_data';

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

  test('toJson sends attachment paths and attachments in order', () {
    final data = Uint8List.fromList(<int>[1, 2, 3]);
    final email = Email(
      attachmentPaths: const <String>['/tmp/a.pdf'],
      attachments: <EmailAttachment>[
        EmailAttachment.data(data, fileName: 'b.csv', mimeType: 'text/csv'),
        const EmailAttachment.file('/tmp/c.png'),
      ],
    );

    expect(email.hasAttachments, isTrue);
    expect(email.toJson()['attachments'], <Map<String, Object>>[
      <String, Object>{'path': '/tmp/a.pdf'},
      <String, Object>{
        'data': data,
        'file_name': 'b.csv',
        'mime_type': 'text/csv',
      },
      <String, Object>{'path': '/tmp/c.png'},
    ]);
  });

  test('in-memory attachments count as attachments', () {
    final email = Email(
      attachments: <EmailAttachment>[
        EmailAttachment.data(Uint8List(0), fileName: 'empty.txt'),
      ],
    );

    expect(email.hasAttachments, isTrue);
    expect(
      const EmailCapabilities.mailto(
        canSend: true,
      ).unsupportedFeaturesFor(email),
      <String>['attachments'],
    );
  });
}
