# flutter_email_sender

Allows sending emails from Flutter using native platform functionality.

On Android it opens an email app via an intent. When several email apps are installed, the user picks one from a chooser that lists only email apps.

On iOS `MFMailComposeViewController` is used to compose an email when an account is set up in Apple Mail.

On macOS `NSSharingService` with `.composeEmail` is used to compose an email.

On Linux `xdg-email` opens the default mail client, such as Thunderbird. Without `xdg-email`, the plugin opens a `mailto:` link, which cannot carry attachments.

When the native composer is unavailable on iOS or macOS, for example on an iPhone without an Apple Mail account, the plugin opens a `mailto:` link in the default mail app (such as Gmail) instead. Attachments and HTML bodies cannot be sent that way, and `getCapabilities()` reports them as unsupported.

The plugin exposes platform capabilities so apps can adapt their UI before sending.

The public API throws typed Dart exceptions rather than exposing raw `PlatformException`s for expected failures.

## Platform Support

| Platform | `cc` | `bcc` | HTML body | Attachments |
| --- | --- | --- | --- | --- |
| Android | Yes | Yes | Yes | Yes |
| iOS | Yes | Yes | Yes | Yes |
| iOS, `mailto:` fallback | Yes | Yes | No | No |
| macOS | No | No | No | Yes |
| macOS, `mailto:` fallback | Yes | Yes | No | No |
| Linux | Yes | Yes | No | Yes |
| Linux, `mailto:` fallback | Yes | Yes | No | No |
| Web | Yes | Yes | No | No |

Web support uses `mailto:` and depends on browser and configured mail client behavior.

On Android, HTML support depends on the email app; Gmail shows the body as plain text.

On Linux, attachments reach Thunderbird installed from the distribution's packages, Evolution and KMail. Thunderbird installed as a Snap (the Ubuntu default) or Flatpak, Claws Mail and webmail receive the email as a `mailto:` link and drop the attachments without an error.


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
    // Other platforms do not report the outcome.
    break;
}
```

On Android and iOS, `send` completes when the user leaves the composer; on macOS, Linux and web, once the composer has been opened.

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

## Attachments

Attach files by path, or in-memory data with a file name:

```dart
final email = Email(
  recipients: ['example@example.com'],
  attachmentPaths: ['/path/to/report.pdf'],
  attachments: [
    EmailAttachment.file('/path/to/photo.jpg'),
    EmailAttachment.data(
      utf8.encode(csv),
      fileName: 'export.csv',
      mimeType: 'text/csv',
    ),
  ],
);
```

Files can be anywhere the app can read; a file that cannot be read makes `send` throw `FlutterEmailSenderPlatformException`. On Android, attachments are copied into the app's cache directory before being shared, so the original file can be deleted once `send` returns. On iOS, the MIME type comes from the file name extension unless `mimeType` is given. On Linux, in-memory data is written to the temporary directory and left there, because Thunderbird reads attachments only when the email is sent.

## Errors

- `FlutterEmailSenderNotAvailableException`: no email composer is currently available.
- `FlutterEmailSenderUnsupportedFeatureException`: requested fields are unsupported on the current platform.
- `FlutterEmailSenderPlatformException`: unexpected platform/plugin error, or an email that iOS failed to send (code `send_failed`).

## Migrating From 10.x To 11.0.0

- `send` now returns an `EmailSendResult`. Existing `await FlutterEmailSender.send(email)` calls keep compiling.
- iOS: `send` completes when the user leaves the composer, not when it opens. Code that ran right after `await send(...)`, such as an "Email sent" message, now runs later; use the result to tell a sent email from a discarded one.
- iOS without an Apple Mail account (and macOS without a native composer): `canSend` is now `true` and `send` opens a `mailto:` link instead of throwing `FlutterEmailSenderNotAvailableException`. Emails with attachments or an HTML body throw `FlutterEmailSenderUnsupportedFeatureException` instead. If you caught `FlutterEmailSenderNotAvailableException` to offer your own fallback, such as a share sheet, also catch `FlutterEmailSenderUnsupportedFeatureException`, or check `supportsAttachments` and `supportsHtmlBody` from `getCapabilities()` before sending:

  ```dart
  try {
    await FlutterEmailSender.send(email);
  } on FlutterEmailSenderNotAvailableException {
    // No mail app can be opened.
  } on FlutterEmailSenderUnsupportedFeatureException {
    // For example attachments while iOS falls back to mailto:.
  }
  ```

- An attachment file that cannot be read now makes `send` throw `FlutterEmailSenderPlatformException` instead of being left out.
- Android: if your app uses AppCompat classes, declare `androidx.appcompat:appcompat` in your app's `build.gradle`; the plugin no longer brings it in.
- Android: the `SENDTO` `mailto` query that earlier versions asked you to add to `AndroidManifest.xml` can be removed.
- Tests: if you replace `FlutterEmailSenderPlatform` with a test double, stub `sendWithResult`; `FlutterEmailSender.send` calls it instead of `send`.

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
  flutter_email_sender_linux:
    path: ../flutter_email_sender/packages/flutter_email_sender_linux
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

## iOS Setup

No setup is needed. Optionally, list `mailto` under `LSApplicationQueriesSchemes` in `ios/Runner/Info.plist` so that `canSend` is accurate when Apple Mail has no account:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>mailto</string>
</array>
```

Without it, iOS does not let the plugin check whether a mail app can open `mailto:` links, so `canSend` is reported as `true` and `send` throws `FlutterEmailSenderNotAvailableException` when none can.

## Linux Setup

No setup is needed. The plugin uses `xdg-email` from `xdg-utils`, which desktop distributions usually include. Without it, `send` opens a `mailto:` link and `getCapabilities()` reports attachments as unsupported.
