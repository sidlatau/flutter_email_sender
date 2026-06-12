class Email {
  const Email({
    this.subject = '',
    this.recipients = const [],
    this.cc = const [],
    this.bcc = const [],
    this.body = '',
    this.attachmentPaths,
    this.isHTML = false,
  });

  final String subject;
  final List<String> recipients;
  final List<String> cc;
  final List<String> bcc;
  final String body;
  final List<String>? attachmentPaths;
  final bool isHTML;

  bool get hasAttachments => attachmentPaths?.isNotEmpty ?? false;
  bool get hasSubject => subject.isNotEmpty;
  bool get hasBody => body.isNotEmpty;

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
