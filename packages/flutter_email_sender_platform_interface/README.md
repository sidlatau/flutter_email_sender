# flutter_email_sender_platform_interface

Platform interface for `flutter_email_sender`.

This package defines the shared `Email`, `EmailCapabilities`, and `FlutterEmailSenderPlatform` API used by federated implementations.

Most applications should depend on `package:flutter_email_sender/flutter_email_sender.dart` instead of using this package directly.

## Usage

This package is intended for authors of platform implementations such as method-channel or web backends.

It exposes:

- `Email`: the request model used by all implementations.
- `EmailCapabilities`: the platform capability contract, including runtime `canSend` availability.
- `FlutterEmailSenderPlatform`: the abstract base class implementations register with.

## End Users

If you are building an application, depend on `flutter_email_sender` instead of this package.
