import 'dart:io';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

Future<bool> downloadBytes({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  try {
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    final result = await Share.shareXFiles(
      <XFile>[XFile(file.path, mimeType: mimeType, name: fileName)],
      text: 'Guardians export',
    );

    return result.status != ShareResultStatus.dismissed;
  } catch (_) {
    return false;
  }
}
