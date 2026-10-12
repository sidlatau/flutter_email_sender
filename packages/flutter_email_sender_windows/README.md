# flutter_email_sender_windows

Windows implementation of `flutter_email_sender`.

Most applications should depend on `package:flutter_email_sender/flutter_email_sender.dart` instead of using this package directly.

## Behavior

- When the default mail client handles Simple MAPI, as classic Outlook and Thunderbird do, `MAPISendMailW` opens its composer with the recipients, cc, bcc, subject, body and attachments.
- The plugin reads the default mail client from `Software\Clients\Mail` in the registry. Without a Simple MAPI client, for example with the new Outlook for Windows, it opens a `mailto:` link through `url_launcher`, so attachments are unsupported.
- `send` completes when `MAPISendMailW` returns, which depending on the mail client is when its composer opens or closes. The call runs on a background isolate.
- In-memory attachments are written to a new folder in the temporary directory and left there, because some mail clients read attachments only when the email is sent.
- HTML bodies are unsupported: Simple MAPI carries plain text only.

## Endorsement

`flutter_email_sender` routes Windows builds to this package automatically, so applications usually do not need a direct dependency on it.
