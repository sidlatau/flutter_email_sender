import 'dart:typed_data';

/// A file attached to an `Email`.
class EmailAttachment {
  /// Attaches the file at [path].
  const EmailAttachment.file(String this.path)
    : data = null,
      fileName = null,
      mimeType = null;

  /// Attaches [data] as a file named [fileName].
  ///
  /// [mimeType] is used on iOS and defaults to the type of the [fileName]
  /// extension; Android and macOS always derive it from [fileName].
  const EmailAttachment.data(
    Uint8List this.data, {
    required String this.fileName,
    this.mimeType,
  }) : path = null;

  /// Absolute path of a file attachment.
  final String? path;

  /// Content of an in-memory attachment.
  final Uint8List? data;

  /// File name of an in-memory attachment.
  final String? fileName;

  /// MIME type of an in-memory attachment.
  final String? mimeType;

  /// Converts this attachment into the platform channel payload.
  Map<String, Object> toJson() => <String, Object>{
    if (path case final path?) 'path': path,
    if (data case final data?) 'data': data,
    if (fileName case final fileName?) 'file_name': fileName,
    if (mimeType case final mimeType?) 'mime_type': mimeType,
  };
}
