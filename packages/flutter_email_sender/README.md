# flutter_email_sender

Allows send emails from flutter using native platform functionality.

In android it opens default mail app via intent.

In iOS `MFMailComposeViewController` is used to compose an email.

In macOS `NSSharingService` with `.composeEmail` is used to compose an email.
The plugin exposes platform capabilities so apps can adapt their UI before sending.

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

If an app requests features that the current platform cannot honor, `send` throws `PlatformException` with code `unsupported`.

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
