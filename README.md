# flutter_email_sender

Allows send emails from flutter using native platform functionality.

In android it opens default mail app via intent. 

In iOS `MFMailComposeViewController` is used to compose an email.

# Example

```dart
final Email email = Email(
  body: 'Email body',
  subject: 'Email subject',
  recipients: ['example@example.com'],
  cc: ['cc@example.com'],
  bcc: ['bcc@example.com'],
  attachmentPaths: ['/path/to/attachment.zip'],
  isHTML: false,
);

await FlutterEmailSender.send(email);

``` 

## Android Setup

With Android 11, package visibility is introduced that alters the ability to query installed applications and packages on a user’s device. To enable your application to get visibility into the packages you will need to add a list of queries into your AndroidManifest.xml.

```
<manifest package="com.mycompany.myapp">
  <queries>
    <intent>
      <action android:name="android.intent.action.SENDTO" />
      <data android:scheme="mailto" />
    </intent>
  </queries>
</manifest>
```

## Getting Started

For help getting started with Flutter, view our online
[documentation](https://flutter.io/).

For help on editing plugin code, view the [documentation](https://flutter.io/developing-packages/#edit-plugin-package).
