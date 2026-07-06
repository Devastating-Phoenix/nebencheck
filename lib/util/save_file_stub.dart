import 'dart:typed_data';

void downloadBytes(Uint8List bytes, String filename, String mimeType) {
  throw UnsupportedError('File download is only supported on the web build.');
}

void openExternal(String url) {
  throw UnsupportedError('External links are only supported on the web build.');
}
