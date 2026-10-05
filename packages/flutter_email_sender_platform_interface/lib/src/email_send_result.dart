/// How the user left the email composer.
enum EmailSendResult {
  /// The email was sent, or queued to be sent.
  sent,

  /// The email was saved as a draft.
  saved,

  /// The email was discarded.
  cancelled,

  /// The platform does not report the outcome.
  ///
  /// Android, macOS and web always return this value.
  unknown,
}
