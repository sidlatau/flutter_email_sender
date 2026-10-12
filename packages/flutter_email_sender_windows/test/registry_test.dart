@TestOn('windows')
library;

import 'package:flutter_email_sender_windows/src/registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hasDefaultMapiClient reads the registry', () {
    expect(hasDefaultMapiClient(), isA<bool>());
  });
}
