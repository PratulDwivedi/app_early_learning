import 'dart:html' as html;
import 'dart:typed_data';

Future<Uint8List?> loadBlobBytes(String blobUrl) async {
  final response = await html.HttpRequest.request(
    blobUrl,
    responseType: 'arraybuffer',
  );
  final payload = response.response;

  if (payload is ByteBuffer) {
    return Uint8List.view(payload);
  }

  if (payload is Uint8List) {
    return payload;
  }

  return null;
}
