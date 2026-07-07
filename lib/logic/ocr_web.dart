import 'dart:js_interop';

/// Bound to `window.ncRunOcr` (defined in web/index.html), which opens a file
/// picker, runs Tesseract.js on the chosen image, and resolves with the
/// recognized text ("" on cancel or failure). Keeping the pick + OCR in JS
/// keeps the Dart interop surface to a single promise call.
@JS('ncRunOcr')
external JSPromise<JSString> _ncRunOcr();

@JS('ncRunOcr')
external JSAny? get _ncRunOcrHandle;

/// True once the OCR helper (and thus the page script) has loaded.
bool get ocrAvailable => _ncRunOcrHandle != null;

/// Picks an image and runs German OCR on it entirely in the browser.
/// Returns the recognized text, or null on cancel / failure.
/// [onProgress] is accepted for API symmetry but not emitted in this build.
Future<String?> pickAndRecognize({
  void Function(double progress)? onProgress,
}) async {
  if (_ncRunOcrHandle == null) return null;
  try {
    final result = (await _ncRunOcr().toDart).toDart;
    return result.trim().isEmpty ? null : result;
  } catch (_) {
    return null;
  }
}
