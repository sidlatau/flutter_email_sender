# flutter_email_sender

Allows send emails from flutter using native platform functionality.

In android it opens default mail app via intent. `compileSdkVersion 28` is used in this plugin and it should be used in app too. 

In iOS `MFMailComposeViewController` is used to compose an email.

# Example

```dart
final Email email = Email(
  body: 'Email body',
  subject: 'Email subject',
  recipients: ['example@example.com'],
  cc: ['cc@example.com'],
  bcc: ['bcc@example.com'],
  attachmentPath: '/path/to/attachment.zip',
  isHTML: false,
);

await FlutterEmailSender.send(email);

``` 

## Getting Started

For help getting started with Flutter, view our online
[documentation](https://flutter.io/).

For help on editing plugin code, view the [documentation](https://flutter.io/developing-packages/#edit-plugin-package).
