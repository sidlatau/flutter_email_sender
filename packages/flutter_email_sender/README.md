# flutter_email_sender

Allows sending emails from Flutter using native platform functionality.

On Android it opens an email app via an intent. When several email apps are installed, the user picks one from a chooser that lists only email apps.

On iOS `MFMailComposeViewController` is used to compose an email. It requires an account set up in Apple Mail; other mail apps such as Gmail are not used.

On macOS `NSSharingService` with `.composeEmail` is used to compose an email.
The plugin exposes platform capabilities so apps can adapt their UI before sending.

The public API throws typed Dart exceptions rather than exposing raw `PlatformException`s for expected failures.

## Platform Support

| Platform | `cc` | `bcc` | HTML body | Attachments |
| --- | --- | --- | --- | --- |
| Android | Yes | Yes | Yes | Yes |
| iOS | Yes | Yes | Yes | Yes |
| macOS | No | No | No | Yes |
| Web | Yes | Yes | No | No |

Web support uses `mailto:` and depends on browser and configured mail client behavior.

On Android, HTML support depends on the email app; Gmail shows the body as plain text.

Attachments can be any file the app can read. On Android they are copied into the app's cache directory before being shared, so the original file can be deleted once `send` returns.

# Example

```dart
final capabilities = await FlutterEmailSender.getCapabilities();

if (!capabilities.canSend) {
  // No configured mail account, simulator, or no available mail client.
}

final Email email = Email(
  body: 'Email body',
  subject: 'Email subject',
  recipients: ['example@example.com'],
  cc: capabilities.supportsCc ? ['cc@example.com'] : const [],
  bcc: capabilities.supportsBcc ? ['bcc@example.com'] : const [],
  attachmentPaths: capabilities.supportsAttachments
      ? ['/path/to/attachment.zip']
      : null,
  isHTML: capabilities.supportsHtmlBody,
);

final result = await FlutterEmailSender.send(email);

switch (result) {
  case EmailSendResult.sent:
  case EmailSendResult.saved:
  case EmailSendResult.cancelled:
    // iOS reports how the user left the composer.
    break;
  case EmailSendResult.unknown:
    // Android, macOS and web do not report the outcome.
    break;
}
```

On Android and iOS, `send` completes when the user leaves the composer; on macOS and web, once the composer has been opened.

```dart
try {
  await FlutterEmailSender.send(email);
} on FlutterEmailSenderNotAvailableException {
  // Email composer is unavailable on this device right now.
} on FlutterEmailSenderUnsupportedFeatureException catch (error) {
  // Requested features are unsupported on the current platform.
  debugPrint('Unsupported: ${error.unsupportedFeatures}');
}
```

## Errors

- `FlutterEmailSenderNotAvailableException`: no email composer is currently available.
- `FlutterEmailSenderUnsupportedFeatureException`: requested fields are unsupported on the current platform.
- `FlutterEmailSenderPlatformException`: unexpected platform/plugin error, or an email that iOS failed to send (code `send_failed`).

## Migrating From 9.x To 10.0.0

- `send` and `getCapabilities` now throw typed Dart exceptions for expected failures.
- Apps that previously caught `PlatformException(code: 'not_available')` should catch `FlutterEmailSenderNotAvailableException` instead.
- Apps that previously caught `PlatformException(code: 'unsupported')` should catch `FlutterEmailSenderUnsupportedFeatureException` instead.
- Use `getCapabilities()` and `EmailCapabilities.canSend` to adapt UI before calling `send`.

## Local Development

When consuming this plugin from a local checkout before all federated packages are published, point your app dependency at `packages/flutter_email_sender` and override the internal federated packages in `pubspec_overrides.yaml`.

Example app `pubspec.yaml`:

```yaml
dependencies:
  flutter_email_sender:
    path: ../flutter_email_sender/packages/flutter_email_sender
```

Example app `pubspec_overrides.yaml`:

```yaml
dependency_overrides:
  flutter_email_sender_method_channel:
    path: ../flutter_email_sender/packages/flutter_email_sender_method_channel
  flutter_email_sender_platform_interface:
    path: ../flutter_email_sender/packages/flutter_email_sender_platform_interface
  flutter_email_sender_web:
    path: ../flutter_email_sender/packages/flutter_email_sender_web
```

Adjust the relative paths to match where your app and local plugin checkout live on disk.

## Android Setup

No `AndroidManifest.xml` changes are needed: the plugin declares the package visibility `<queries>` it uses. Apps that added a `SENDTO` `mailto` query for earlier versions can remove it.
