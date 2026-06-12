# flutter_email_sender

Allows send emails from flutter using native platform functionality.

In android it opens default mail app via intent.

In iOS `MFMailComposeViewController` is used to compose an email.

In macOS `NSSharingService` with `.composeEmail` is used to compose an email.
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

await FlutterEmailSender.send(email);
```

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
- `FlutterEmailSenderPlatformException`: unexpected platform/plugin error.

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

With Android 11, package visibility is introduced that alters the ability to query installed applications and packages on a user's device. To enable your application to get visibility into the packages you will need to add a list of queries into your `AndroidManifest.xml`.

```xml
<manifest package="com.mycompany.myapp">
  <queries>
    <intent>
      <action android:name="android.intent.action.SENDTO" />
      <data android:scheme="mailto" />
    </intent>
  </queries>
</manifest>
```
