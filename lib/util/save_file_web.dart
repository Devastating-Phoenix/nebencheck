// TODO(migration): move to package:web + dart:js_interop once the pinned
// Flutter SDK is bumped; dart:html still works but is deprecated.
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

/// Triggers a browser download of [bytes] as [filename].
void downloadBytes(Uint8List bytes, String filename, String mimeType) {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrl(blob);
  final anchor = html.AnchorElement(href: url)..download = filename;
  html.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}

/// Opens [url] (e.g. a mailto: link) via the browser.
void openExternal(String url) {
  html.window.open(url, '_blank');
}
