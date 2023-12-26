enum MailerResponse {
  /// [ios] only - mail was sent, for [android] it is always sent
  sent,

  /// [ios] only - mail was saved as draft
  saved,

  /// [ios] only - mail was cancelled
  cancelled,

  /// [ios] only - result is unknown
  unknown,
}

MailerResponse sendPlatformResponse(final String? response) {
  switch (response) {
    case 'saved':
      return MailerResponse.saved;
    case 'cancelled':
      return MailerResponse.cancelled;
    case 'sent':
    default:
      return MailerResponse.sent;
  }
}
