import 'dart:html' as html;
import 'dart:typed_data';

Future<bool> downloadBytes({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  try {
    final blob = html.Blob([bytes], mimeType);
    final objectUrl = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: objectUrl)
      ..setAttribute('download', fileName)
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();

    html.Url.revokeObjectUrl(objectUrl);
    return true;
  } catch (_) {
    return false;
  }
}
