import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_email_sender_method_channel/flutter_email_sender_method_channel.dart';
import 'package:flutter_email_sender_platform_interface/flutter_email_sender_platform_interface.dart';

export 'package:flutter_email_sender_platform_interface/flutter_email_sender_platform_interface.dart'
    show Email, EmailCapabilities;

class FlutterEmailSender {
  static FlutterEmailSenderPlatform get _platform {
    if (FlutterEmailSenderPlatform.usesDefaultInstance && !kIsWeb) {
      FlutterEmailSenderPlatform.instance = MethodChannelFlutterEmailSender();
    }

    return FlutterEmailSenderPlatform.instance;
  }

  static Future<void> send(Email mail) {
    return _platform.send(mail);
  }

  static Future<EmailCapabilities> getCapabilities() {
    return _platform.getCapabilities();
  }
}
