# flutter_email_sender_method_channel

Method-channel implementation of `flutter_email_sender` for Android, iOS, and macOS.

This package is an endorsed federated implementation and is usually consumed through `package:flutter_email_sender/flutter_email_sender.dart`.

## Supported Platforms

- Android
- iOS
- macOS

## Endorsement

`flutter_email_sender` routes supported native platforms to this package automatically. Applications normally should not depend on this package directly.

## Implementation Notes

- Android uses intents to open an email app.
- iOS uses `MFMailComposeViewController`.
- macOS uses `NSSharingService` with `.composeEmail`.
