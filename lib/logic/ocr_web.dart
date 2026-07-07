import 'dart:js_interop';

/// Bound to `window.ncPickAndExtract(cameraOnly)` (defined in web/index.html),
/// which opens a picker and resolves with the file's text — OCR for images,
/// embedded text for Word/PDF/txt. Everything runs on-device.
@JS('ncPickAndExtract')
external JSPromise<JSString> _ncPickAndExtract(JSBoolean cameraOnly);

@JS('ncPickAndExtract')
external JSAny? get _handle;

/// True once the import helper (and page scripts) have loaded.
bool get ocrAvailable => _handle != null;

Future<String?> _pick(bool cameraOnly) async {
  if (_handle == null) return null;
  try {
    final result = (await _ncPickAndExtract(cameraOnly.toJS).toDart).toDart;
    return result.trim().isEmpty ? null : result;
  } catch (_) {
    return null;
  }
}

/// Camera photo → OCR. [onProgress] accepted for API symmetry, not emitted.
Future<String?> pickAndRecognize({
  void Function(double progress)? onProgress,
}) =>
    _pick(true);

/// A document (Word, PDF, text) or an image file → text.
Future<String?> pickAndReadDocument({
  void Function(double progress)? onProgress,
}) =>
    _pick(false);
