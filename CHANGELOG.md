## 6.0.1

- Use SEND_TO action for Android (fixes #91)

## 6.0.0

- Updated android dependencies, using gradle 8.0

## 5.2.0

- Updated android references: updated compile and target SDK to 33
- Fixed attachment adding problem in Android 13 (#87)
- Support Objective-C project with Podfile no use_frameworks - thanks @fachrifaul

## 5.1.0

- Updated android references: replaced references for jcenter, updated compile and target SDK to 31 (#82)
- Fixed issue for attaching file from application documents directory (#21, #35, #66)
- Updated example app (#52)

## 5.0.2

- Fixed problem when future never completes (#73) - thanks @zuzi-m

## 5.0.1

- Fixed Android v2 embedding problem - thanks @sergey-triputsco

## 5.0.0

- Migrated to null-safety.

## 4.0.0

- Android: show only email apps in the chooser - thanks to @ttencate

## 3.0.1

- Improved documentation.

## 3.0.0

- Added ability to attach multiple files - thanks to @michalsuryntequiqo
- BREAKING CHANGE: `attachmentPath` parameter becomes `attachmentPaths`

## 2.2.2

- Updated Android dependencies.

## 2.2.1

- Fixed problem with setting BCC in iOS. (Issue #29)

## 2.2.0

- Improved email client app selection in Android.

## 2.1.0

- Added HTML support - thanks to @trancanhluc.

## 2.0.3

- Finished migration to Android X.

## 2.0.2

- Configured external files path for FileProvider (Issue #10).

## 2.0.1

- Finish future when email screen is closed. (Issue #15).

## 2.0.0

- Migrated to AndroidX.

## 1.2.0

- Updated gradle and Kotlin versions to work with Android Studio 3.3.

## 1.1.0

- Updated Swift version to 4.2.

## 1.0.1

- Fixed compilation problem in flutter > 0.10.0 version (issue #5).

## 1.0.0

- Added custom file provider to work nicely with 'open_file' plugin (issue #3).

## 0.1.0

- Fixed problem, that email body was not provided to mail app in iOS part.

## 0.0.4

- Fixed AndroidRuntimeException when calling startActivity (Issue #1).

## 0.0.3

- Fixed grammar.

## 0.0.2

- Fixed homepage link.

## 0.0.1

- Works on Android and iOS. On Android Intent is launched, on iOS MFMailComposeViewController is used to compose an email.
