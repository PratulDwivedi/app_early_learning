import 'dart:typed_data';

import 'download_helper_stub.dart'
    if (dart.library.io) 'download_helper_io.dart'
    if (dart.library.html) 'download_helper_web.dart' as impl;

Future<bool> downloadBytes({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) {
  return impl.downloadBytes(
    bytes: bytes,
    fileName: fileName,
    mimeType: mimeType,
  );
}
