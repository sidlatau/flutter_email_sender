## 2.0.0

- BREAKING: iOS, macOS: open the `mailto:` link built by the Dart side when the native composer is unavailable, and report the `mailto` composer from `getCapabilities` (#26, #47, #54, #76).
- BREAKING: iOS: complete `send` when the composer closes with `sent`, `saved` or `cancelled`, or fail with `send_failed` (#72, #77).
- BREAKING: fail `send` when an attachment file cannot be read, on Android, iOS and macOS.
- BREAKING: Android: depend on `androidx.core` 1.16.0 instead of exposing `androidx.appcompat`; raise `minSdk` to 24.
- Android: send a typed `SEND`/`SEND_MULTIPLE` intent to each email app's own activity instead of using a `mailto:` selector, so Thunderbird-based apps keep a single attachment (#131) and the chooser lists only email apps (#95).
- Android: copy attachments into `cacheDir/flutter_email_sender/` and expose only that folder through the `FileProvider`, so files from any readable location work (#48, #100).
- Android: declare the package visibility `<queries>` in the plugin manifest.
- Support in-memory attachments: Android writes them into the attachment folder, iOS passes them to the composer, and macOS writes them to a temporary folder (#119).
- iOS: present the composer from the topmost view controller (#117, #71).
- iOS: derive attachment MIME types from the file extension.
- iOS, macOS: align the podspec deployment targets with Swift Package Manager (iOS 13.0, macOS 10.15).
- Requires `flutter_email_sender_platform_interface` 1.1.0.

## 1.0.1

- Fix the iOS and macOS podspec `license :file` path to point at the package's own bundled `LICENSE`, removing a CocoaPods warning on every `pod install` in consumer apps.

## 1.0.0

- Initial method-channel implementation package for `flutter_email_sender`.
- Supports Android, iOS, and macOS.
