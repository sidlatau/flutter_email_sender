import 'dart:ffi';

import 'package:ffi/ffi.dart';

/// An email in the form Simple MAPI takes it.
class MapiMail {
  /// Creates an email for [sendMapiMail].
  const MapiMail({
    this.subject,
    this.body,
    this.to = const [],
    this.cc = const [],
    this.bcc = const [],
    this.attachments = const [],
  });

  /// The subject line.
  final String? subject;

  /// The plain text body.
  final String? body;

  /// The primary recipients.
  final List<String> to;

  /// The carbon copy recipients.
  final List<String> cc;

  /// The blind carbon copy recipients.
  final List<String> bcc;

  /// The attachments, each as a file path and the name shown to the user.
  final List<({String path, String name})> attachments;
}

/// `MAPI_E_USER_ABORT`.
const int mapiUserAbort = 1;

/// `MAPI_E_LOGIN_FAILURE`.
const int mapiLoginFailure = 3;

const int _mapiLogonUi = 0x1;
const int _mapiDialog = 0x8;
const int _mapiTo = 1;
const int _mapiCc = 2;
const int _mapiBcc = 3;
const int _coinitApartmentThreaded = 0x2;

/// Opens the default Simple MAPI client's composer with [mail] and returns the
/// `MAPISendMailW` result code.
///
/// Blocks until the mail client returns, which for some clients is when the
/// user closes the composer, so call it on a background isolate.
int sendMapiMail(MapiMail mail) {
  final ole32 = DynamicLibrary.open('ole32.dll');
  final coInitializeEx = ole32
      .lookupFunction<
        Int32 Function(Pointer<Void>, Uint32),
        int Function(Pointer<Void>, int)
      >('CoInitializeEx');
  final coUninitialize = ole32.lookupFunction<Void Function(), void Function()>(
    'CoUninitialize',
  );
  final mapiSendMail = DynamicLibrary.open('mapi32.dll')
      .lookupFunction<
        Uint32 Function(
          UintPtr,
          UintPtr,
          Pointer<MapiMessageW>,
          Uint32,
          Uint32,
        ),
        int Function(int, int, Pointer<MapiMessageW>, int, int)
      >('MAPISendMailW');

  // Mail clients such as Outlook use COM, which this isolate's thread has not
  // initialized.
  final comInitialized = coInitializeEx(nullptr, _coinitApartmentThreaded) >= 0;
  try {
    return using(
      (arena) => mapiSendMail(
        0,
        0,
        allocateMapiMessage(mail, arena),
        _mapiLogonUi | _mapiDialog,
        0,
      ),
    );
  } finally {
    if (comInitialized) {
      coUninitialize();
    }
  }
}

/// Allocates the `MapiMessageW` structure for [mail] with [allocator].
Pointer<MapiMessageW> allocateMapiMessage(MapiMail mail, Allocator allocator) {
  Pointer<Utf16> text(String? value) => value == null || value.isEmpty
      ? nullptr
      : value.toNativeUtf16(allocator: allocator);

  final recipients = [
    for (final address in mail.to) (_mapiTo, address),
    for (final address in mail.cc) (_mapiCc, address),
    for (final address in mail.bcc) (_mapiBcc, address),
  ];
  final recips = recipients.isEmpty
      ? nullptr
      : allocator<MapiRecipDescW>(recipients.length);
  for (final (index, (recipClass, address)) in recipients.indexed) {
    recips[index]
      ..ulReserved = 0
      ..ulRecipClass = recipClass
      ..lpszName = text(address)
      ..lpszAddress = text('SMTP:$address')
      ..ulEIDSize = 0
      ..lpEntryID = nullptr;
  }

  final files = mail.attachments.isEmpty
      ? nullptr
      : allocator<MapiFileDescW>(mail.attachments.length);
  for (final (index, attachment) in mail.attachments.indexed) {
    files[index]
      ..ulReserved = 0
      ..flFlags = 0
      ..nPosition = 0xFFFFFFFF
      ..lpszPathName = text(attachment.path)
      ..lpszFileName = text(attachment.name)
      ..lpFileType = nullptr;
  }

  return allocator<MapiMessageW>()
    ..ref.ulReserved = 0
    ..ref.lpszSubject = text(mail.subject)
    ..ref.lpszNoteText = text(mail.body)
    ..ref.lpszMessageType = nullptr
    ..ref.lpszDateReceived = nullptr
    ..ref.lpszConversationID = nullptr
    ..ref.flFlags = 0
    ..ref.lpOriginator = nullptr
    ..ref.nRecipCount = recipients.length
    ..ref.lpRecips = recips
    ..ref.nFileCount = mail.attachments.length
    ..ref.lpFiles = files;
}

/// `MapiMessageW` from `mapi.h`.
final class MapiMessageW extends Struct {
  @Uint32()
  external int ulReserved;
  external Pointer<Utf16> lpszSubject;
  external Pointer<Utf16> lpszNoteText;
  external Pointer<Utf16> lpszMessageType;
  external Pointer<Utf16> lpszDateReceived;
  external Pointer<Utf16> lpszConversationID;
  @Uint32()
  external int flFlags;
  external Pointer<MapiRecipDescW> lpOriginator;
  @Uint32()
  external int nRecipCount;
  external Pointer<MapiRecipDescW> lpRecips;
  @Uint32()
  external int nFileCount;
  external Pointer<MapiFileDescW> lpFiles;
}

/// `MapiRecipDescW` from `mapi.h`.
final class MapiRecipDescW extends Struct {
  @Uint32()
  external int ulReserved;
  @Uint32()
  external int ulRecipClass;
  external Pointer<Utf16> lpszName;
  external Pointer<Utf16> lpszAddress;
  @Uint32()
  external int ulEIDSize;
  external Pointer<Void> lpEntryID;
}

/// `MapiFileDescW` from `mapi.h`.
final class MapiFileDescW extends Struct {
  @Uint32()
  external int ulReserved;
  @Uint32()
  external int flFlags;
  @Uint32()
  external int nPosition;
  external Pointer<Utf16> lpszPathName;
  external Pointer<Utf16> lpszFileName;
  external Pointer<Void> lpFileType;
}
