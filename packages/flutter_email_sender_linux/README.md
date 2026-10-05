# flutter_email_sender_linux

Linux implementation of `flutter_email_sender`.

Most applications should depend on `package:flutter_email_sender/flutter_email_sender.dart` instead of using this package directly.

## Behavior

- Opens the default mail client with `xdg-email` from `xdg-utils`. Thunderbird installed from the distribution's packages gets the email on its command line; other mail clients get a `mailto:` link with `attach` parameters.
- Attachments reach Thunderbird from distribution packages, Evolution and KMail. Thunderbird as a Snap or Flatpak, Claws Mail and webmail drop them without an error.
- `send` completes once `xdg-email` exits, or after two seconds while it is still running: when the mail client is not running yet, `xdg-email` usually waits until the user quits it.
- In-memory attachments are written to a new folder in the temporary directory and left there, because Thunderbird reads attachments only when the email is sent.
- Without `xdg-email`, opens a `mailto:` link through `url_launcher`, so attachments are unsupported.
- HTML bodies are unsupported.

## Endorsement

`flutter_email_sender` routes Linux builds to this package automatically, so applications usually do not need a direct dependency on it.
