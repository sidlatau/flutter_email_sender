import 'email_attachment.dart';

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
    this.attachments = const [],
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

  /// Attachments given as files or in-memory data, sent after
  /// [attachmentPaths].
  final List<EmailAttachment> attachments;

  /// Whether [body] should be treated as HTML instead of plain text.
  final bool isHTML;

  /// Whether at least one attachment was provided.
  bool get hasAttachments =>
      (attachmentPaths?.isNotEmpty ?? false) || attachments.isNotEmpty;

  /// Whether a non-empty subject was provided.
  bool get hasSubject => subject.isNotEmpty;

  /// Whether a non-empty body was provided.
  bool get hasBody => body.isNotEmpty;

  /// A `mailto:` URI with the recipients, subject and body.
  ///
  /// Attachments and HTML formatting cannot be expressed in a `mailto:` URI.
  Uri toMailtoUri() {
    final queryParameters = <String, String>{
      if (hasSubject) 'subject': subject,
      if (cc.isNotEmpty) 'cc': cc.join(','),
      if (bcc.isNotEmpty) 'bcc': bcc.join(','),
      if (hasBody) 'body': body,
    };

    return Uri(
      scheme: 'mailto',
      path: recipients.join(','),
      query: queryParameters.isEmpty
          ? null
          : queryParameters.entries
                .map(
                  (entry) =>
                      '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}',
                )
                .join('&'),
    );
  }

  /// Converts this request into the platform channel payload.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'subject': subject,
      'body': body,
      'recipients': recipients,
      'cc': cc,
      'bcc': bcc,
      'attachment_paths': attachmentPaths,
      'attachments': <Map<String, Object>>[
        ...?attachmentPaths?.map((path) => EmailAttachment.file(path).toJson()),
        ...attachments.map((attachment) => attachment.toJson()),
      ],
      'is_html': isHTML,
    };
  }
}
