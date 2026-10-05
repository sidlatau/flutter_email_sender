import 'package:flutter_email_sender_platform_interface/flutter_email_sender_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

class _SendOnlyPlatform extends FlutterEmailSenderPlatform {
  Email? sentEmail;

  @override
  Future<void> send(Email email) async {
    sentEmail = email;
  }

  @override
  Future<EmailCapabilities> getCapabilities() async =>
      const EmailCapabilities.none();
}

void main() {
  test(
    'sendWithResult sends and reports an unknown result by default',
    () async {
      final platform = _SendOnlyPlatform();
      const email = Email(subject: 'subject');

      final result = await platform.sendWithResult(email);

      expect(platform.sentEmail, same(email));
      expect(result, EmailSendResult.unknown);
    },
  );
}
