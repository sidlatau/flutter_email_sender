## Unreleased

- Build the `mailto:` link with `Email.toMailtoUri()` from the platform interface; no behavior change.
- Requires `flutter_email_sender_platform_interface` 1.1.0.

## 1.0.0

- Initial web implementation package for `flutter_email_sender`.
- Uses `mailto:` and explicitly rejects unsupported features such as attachments and HTML body.
