/// Immutable email request passed to the plugin.
class Email {
  /// Creates an email request with optional recipients, body, and attachments.
  const Email({
    this.subject = '',
    this.recipients = const [],
    this.cc = const [],
    this.bcc = const [],
    this.body = '',
    this.attachmentPaths,
    this.isHTML = false,
  });

  /// Subject line for the composed email.
  final String subject;

  /// Primary recipients.
  final List<String> recipients;

  /// Carbon copy recipients.
  final List<String> cc;

  /// Blind carbon copy recipients.
  final List<String> bcc;

  /// Body content for the email.
  final String body;

  /// Absolute attachment file paths, when supported by the platform.
  final List<String>? attachmentPaths;

  /// Whether [body] should be treated as HTML instead of plain text.
  final bool isHTML;

  /// Whether at least one attachment was provided.
  bool get hasAttachments => attachmentPaths?.isNotEmpty ?? false;

  /// Whether a non-empty subject was provided.
  bool get hasSubject => subject.isNotEmpty;

  /// Whether a non-empty body was provided.
  bool get hasBody => body.isNotEmpty;

  /// Converts this request into the platform channel payload.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'subject': subject,
      'body': body,
      'recipients': recipients,
      'cc': cc,
      'bcc': bcc,
      'attachment_paths': attachmentPaths,
      'is_html': isHTML,
    };
  }
}
