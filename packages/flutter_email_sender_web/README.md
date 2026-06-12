# flutter_email_sender_web

Web implementation of `flutter_email_sender`.

This package is an endorsed federated implementation that uses `mailto:` URLs.

Most applications should depend on `package:flutter_email_sender/flutter_email_sender.dart` instead of using this package directly.

## Behavior

- Uses `mailto:` to hand off composition to the browser and configured mail client.
- Supports recipients, cc, bcc, subject, and plain-text body.
- Does not support attachments or HTML body.

## Endorsement

`flutter_email_sender` routes web builds to this package automatically, so applications usually do not need a direct dependency on it.
