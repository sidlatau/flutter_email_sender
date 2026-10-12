# Platform notes

Why each platform implementation works the way it does, and the platform behavior it relies on. Most regressions in this plugin came from changes that broke one of these points, so check changes against them.

## Android

### Intents

Without attachments the plugin opens `ACTION_SENDTO` with `mailto:`. With attachments it queries the `mailto:` handlers and sends each email app's own `SEND` activity a typed `ACTION_SEND` / `ACTION_SEND_MULTIPLE` (`*/*`): directly when one email app is installed, otherwise through a chooser that excludes every non-email share target. The intent code broke in 5.2.0, 6.0.1 and 10.0.0; these facts explain why:

- A `mailto:` selector only resolves an untyped intent. Android resolves the selector with the outer intent's MIME type, and `mailto:` filters declare none, so a typed intent with a selector finds no activity ("No email clients found").
- `Intent.setData()` clears the type and `Intent.setType()` clears the data.
- Thunderbird's `MessageCompose` adds `EXTRA_STREAM` attachments only when `intent.type != null` ([#131]). It takes the real MIME type from `ContentResolver.getType()`, so `*/*` is enough.
- With a selector, or an explicit component taken from the `mailto:` query, the `SEND` intent goes to the activity that handles `mailto:`. Apps that handle attachments in a different activity lose them.
- The share sheet shows at most two `EXTRA_INITIAL_INTENTS` (`ChooserActivity.MAX_EXTRA_INITIAL_INTENTS = 2`), so a chooser built from per-app intents hides the fourth and later email apps. `EXTRA_EXCLUDE_COMPONENTS` on a typed chooser has no such limit ([#95]).
- `setPackage()` with `*/*` can match several activities in one package. Gmail's Chat activities accept `SEND` for text, images and video, so the activity must be chosen explicitly.
- The plugin manifest declares the `<queries>` for `SENDTO mailto`, `SEND` and `SEND_MULTIPLE`. Before 11.0 apps had to declare them, and without them Android 11+ hid every mail app, so `send` failed with "No email clients found!" with or without attachments ([#115]).

### Attachments

- Attachments are copied off the main thread into `filesDir/flutter_email_sender/<send id>/<index>/<file name>`, the `FileProvider`'s only root. Earlier versions exposed the whole cache, files and external storage directories ([#100]). Any path the app can read works, and two attachments with the same name stay distinct.
- The copies are kept for three days and deleted on a later send. Mail apps read attachments when they upload the email, which can be long after the composer closes, for example while offline. 11.0 used `cacheDir`, which Android clears when storage runs low, and Gmail then failed with "Couldn't send attachment" ([#84]). To reproduce such failures: go offline, send, run `adb shell pm trim-caches 999G`, go online.
- The paths resource is called `flutter_email_sender_file_paths`, so an app or library resource named `shared_file_paths` cannot override it.
- No persistent URI grants: Gmail keeps the intent's read grant alive in a started service until it uploads, and a background kill keeps it. Only a force-stop of Gmail drops it, and force-stop cancels Gmail's pending work by design.

### Other

- HTML goes in `EXTRA_HTML_TEXT` with a `Spanned` `EXTRA_TEXT`. Gmail ignores the HTML and shows plain text ([#30]).
- `PackageManager.resolveActivity(Intent, int)` and `queryIntentActivities(Intent, int)` were deprecated in API 33 only; API 34 removed the deprecation. The `ResolveInfoFlags` overloads need API 33, above `minSdk` 24.
- `androidx.core` stays at 1.16.0: 1.17.0 requires AGP 8.9.1 and 1.19.x requires AGP 9.1 and compileSdk 37, while Flutter 3.44, the minimum supported version, still builds apps with AGP 8.6.0. Raise it together with the minimum Flutter version.
- The plugin declares no Kotlin standard library dependency; the app's Kotlin provides it. 6.x pinned `kotlin-stdlib-jdk7/8`, which duplicated classes in apps on Kotlin 1.8+ ([#111]).
- Gmail's own back arrow in its composer opens the Gmail inbox in a new task, so the user does not return to the app; the system Back gesture does return ([#53]).

## iOS and macOS

- The composer is presented from the top of `registrar.viewController`'s presentation chain. Presenting on `keyWindow.rootViewController` failed when it was already presenting something, and `send` never completed ([#117], [#71]).
- `send` completes when the composer is dismissed, with the `MFMailComposeResult`; `.failed` throws `send_failed`, and swipe-to-dismiss counts as cancelled.
- `MFMailComposeViewController` works only with an account in Apple Mail. Without one, `send` opens a `mailto:` link in the default mail app, which cannot carry attachments or HTML, and `getCapabilities` says so. `canOpenURL` answers only for schemes listed in `LSApplicationQueriesSchemes`, so without that entry `canSend` is reported as `true`.
- Attachment MIME types come from the file extension (`UTType`), and an unreadable attachment fails `send` before the composer opens.
- macOS uses `NSSharingService` with `.composeEmail`, which takes no cc or bcc, writes in-memory attachments to a temporary folder, and falls back to `mailto:` like iOS when no composer is available.
- Composing in Gmail or Outlook on iOS is possible only through their URL schemes, and never with attachments.
- `[PPT] Error creating the CFMessagePort` and `AXRuntimeCommon … Permission denied` in the console come from iOS around the out-of-process mail composer; nothing fails ([#79]).

## Linux

- `flutter_email_sender_linux` runs `xdg-email --utf8 [--attach path]... <Email.toMailtoUri()>`. Passing our own `mailto:` URI avoids xdg-email's `url_encode` (dash's `echo` interprets backslashes) and its "unexpected argument" error for recipients without `@`.
- xdg-email special-cases Thunderbird (`thunderbird -compose "to='..',subject=..,attachment='..'"`). Every other client gets the `mailto:` link with `attach=` parameters through `gio open`, `kde-open` or `xdg-open`, and some clients drop those since the 2020 "mailto: attach" CVEs.
- When Thunderbird is not running, `thunderbird -compose` runs it in the foreground, so xdg-email exits only when Thunderbird quits. Failures exit within about 50 ms (1 syntax, 2 missing file, 3 no tool, 4 action failed, 5 unreadable), so `send` waits up to 2 s for the exit code, then treats the composer as open.
- Without `xdg-email`, for example inside a Snap, the plugin opens `mailto:` through `url_launcher`.
- In-memory data goes to a new `0700` folder in the temporary directory and is not deleted, because Thunderbird reads attachments only when the email is sent.
- Client results (Debian trixie, xdg-utils 1.2.1): Thunderbird from distribution packages, Evolution and KMail receive attachments. Thunderbird as a Snap or Flatpak and Claws Mail drop them silently; Snap and Flatpak apps also cannot read files in `/tmp`.

## Windows

- `flutter_email_sender_windows` calls Simple MAPI (`MAPISendMailW`), like .NET MAUI Essentials, LibreOffice and Windows "Send to → Mail recipient". WinRT `EmailManager` fails in desktop apps with `0x80070032` (dotnet/maui#5353).
- The new Outlook for Windows has no MAPI. Without a Simple MAPI client as the default, `MAPISendMailW` shows a "There is no email program associated" message box instead of returning an error (dotnet/maui#19643). The plugin therefore reads `Software\Clients\Mail` (HKCU, then HKLM) and calls MAPI only when the default client's subkey has `DLLPath` or `MSIComponentID`; otherwise it opens `mailto:`.
- The dialog is modal (`MAPI_DIALOG | MAPI_LOGON_UI`) and runs on a background isolate with COM initialized as STA. LibreOffice avoids `MAPI_DIALOG_MODELESS` because it "has many problems and crashes Outlook 2016".
- `MAPI_E_USER_ABORT` counts as success, and recipients use `lpszAddress = "SMTP:<address>"`, both as in LibreOffice's `senddoc`.
- Simple MAPI carries no HTML body.
- 1.0.0 was released without running against a real mail client; CI only builds the example and calls the registry code on `windows-latest` ([#88]).

## Web

The web implementation opens a `mailto:` link: no attachments and no HTML.

## Rejected

- Pigeon: the method channel has two methods, so type safety would not pay for the generated code.
- Letting the app list and target specific mail apps: the Android chooser already shows only email apps, and on iOS it would need `LSApplicationQueriesSchemes` entries and could never attach files.

[#30]: https://github.com/sidlatau/flutter_email_sender/issues/30
[#53]: https://github.com/sidlatau/flutter_email_sender/issues/53
[#71]: https://github.com/sidlatau/flutter_email_sender/issues/71
[#79]: https://github.com/sidlatau/flutter_email_sender/issues/79
[#84]: https://github.com/sidlatau/flutter_email_sender/issues/84
[#88]: https://github.com/sidlatau/flutter_email_sender/issues/88
[#95]: https://github.com/sidlatau/flutter_email_sender/issues/95
[#100]: https://github.com/sidlatau/flutter_email_sender/issues/100
[#111]: https://github.com/sidlatau/flutter_email_sender/issues/111
[#115]: https://github.com/sidlatau/flutter_email_sender/issues/115
[#117]: https://github.com/sidlatau/flutter_email_sender/issues/117
[#131]: https://github.com/sidlatau/flutter_email_sender/issues/131
