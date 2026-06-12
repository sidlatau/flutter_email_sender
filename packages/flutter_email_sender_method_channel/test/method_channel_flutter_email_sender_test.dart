import 'package:flutter/services.dart';
import 'package:flutter_email_sender_method_channel/flutter_email_sender_method_channel.dart';
import 'package:flutter_email_sender_platform_interface/flutter_email_sender_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter_email_sender');
  final log = <MethodCall>[];
  final plugin = MethodChannelFlutterEmailSender();

  setUp(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          log.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('send forwards email over the method channel', () async {
    await plugin.send(
      const Email(subject: 'Hi', recipients: <String>['to@example.com']),
    );

    expect(log, hasLength(1));
    expect(log.single.method, 'send');
    expect((log.single.arguments as Map<Object?, Object?>)['subject'], 'Hi');
  });
}
