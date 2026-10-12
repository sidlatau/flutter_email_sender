import 'dart:ffi';

import 'package:ffi/ffi.dart';

const int _hkeyCurrentUser = -0x7FFFFFFF;
const int _hkeyLocalMachine = -0x7FFFFFFE;
const int _rrfRtRegSz = 0x2;
const int _rrfRtRegExpandSz = 0x4;
const int _rrfNoExpand = 0x10000000;
const String _mailClientsKey = r'Software\Clients\Mail';

/// Whether the default mail client handles Simple MAPI, as classic Outlook
/// and Thunderbird do.
///
/// Without such a client, `MAPISendMailW` shows an error message box instead
/// of returning an error.
bool hasDefaultMapiClient() {
  final regGetValue = DynamicLibrary.open('advapi32.dll')
      .lookupFunction<
        Int32 Function(
          IntPtr,
          Pointer<Utf16>,
          Pointer<Utf16>,
          Uint32,
          Pointer<Uint32>,
          Pointer<Void>,
          Pointer<Uint32>,
        ),
        int Function(
          int,
          Pointer<Utf16>,
          Pointer<Utf16>,
          int,
          Pointer<Uint32>,
          Pointer<Void>,
          Pointer<Uint32>,
        )
      >('RegGetValueW');

  String? read(int root, String key, String? value) => using((arena) {
    const flags = _rrfRtRegSz | _rrfRtRegExpandSz | _rrfNoExpand;
    final keyName = key.toNativeUtf16(allocator: arena);
    final valueName = value?.toNativeUtf16(allocator: arena) ?? nullptr;
    final size = arena<Uint32>();
    if (regGetValue(root, keyName, valueName, flags, nullptr, nullptr, size) !=
        0) {
      return null;
    }
    final data = arena<Uint8>(size.value).cast<Utf16>();
    if (regGetValue(
          root,
          keyName,
          valueName,
          flags,
          nullptr,
          data.cast(),
          size,
        ) !=
        0) {
      return null;
    }
    final text = data.toDartString();
    return text.isEmpty ? null : text;
  });

  final client =
      read(_hkeyCurrentUser, _mailClientsKey, null) ??
      read(_hkeyLocalMachine, _mailClientsKey, null);
  if (client == null) {
    return false;
  }
  final clientKey = '$_mailClientsKey\\$client';
  return [_hkeyCurrentUser, _hkeyLocalMachine].any(
    (root) =>
        read(root, clientKey, 'DLLPath') != null ||
        read(root, clientKey, 'MSIComponentID') != null,
  );
}
