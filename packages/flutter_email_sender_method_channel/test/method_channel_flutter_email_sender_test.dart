import 'package:flutter/services.dart';
import 'package:flutter_email_sender_method_channel/flutter_email_sender_method_channel.dart';
import 'package:flutter_email_sender_platform_interface/flutter_email_sender_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter_email_sender');
  final log = <MethodCall>[];
  final plugin = MethodChannelFlutterEmailSender();
  String? nativeSendResult;

  setUp(() {
    log.clear();
    nativeSendResult = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          log.add(call);
          if (call.method == 'getCapabilities') {
            return <String, bool>{'canSend': true};
          }
          return nativeSendResult;
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

    expect(log, hasLength(2));
    expect(log.first.method, 'getCapabilities');
    expect(log.last.method, 'send');
    expect((log.last.arguments as Map<Object?, Object?>)['subject'], 'Hi');
  });

  test('sendWithResult maps the native result', () async {
    for (final result in ['sent', 'saved', 'cancelled']) {
      nativeSendResult = result;

      expect(
        await plugin.sendWithResult(const Email()),
        EmailSendResult.values.byName(result),
      );
    }
  });

  test(
    'sendWithResult returns unknown when native code reports nothing',
    () async {
      expect(
        await plugin.sendWithResult(const Email()),
        EmailSendResult.unknown,
      );

      nativeSendResult = 'unexpected';
      expect(
        await plugin.sendWithResult(const Email()),
        EmailSendResult.unknown,
      );
    },
  );

  test('getCapabilities reads runtime canSend from native code', () async {
    final capabilities = await plugin.getCapabilities();

    expect(log, hasLength(1));
    expect(log.single.method, 'getCapabilities');
    expect(capabilities.canSend, isTrue);
    expect(capabilities.supportsAttachments, isTrue);
  });
}
