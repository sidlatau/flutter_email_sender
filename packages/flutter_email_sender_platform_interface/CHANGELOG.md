## 1.1.0

- Add `EmailSendResult` and `FlutterEmailSenderPlatform.sendWithResult`, which calls `send` and returns `EmailSendResult.unknown` unless overridden.
- Add `Email.toMailtoUri()` and `EmailCapabilities.mailto()`.
- Add `EmailAttachment` and `Email.attachments`; the channel payload lists every attachment under `attachments`.

## 1.0.0

- Initial federated platform interface for `flutter_email_sender`.
- Defines `Email`, `EmailCapabilities`, and `FlutterEmailSenderPlatform`.
