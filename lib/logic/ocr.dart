/// On-device OCR for the "upload a photo of your statement" feature (beta).
/// Web-only (runs Tesseract.js in the browser via WASM — the image never
/// leaves the device); the VM stub is inert so `flutter test` is unaffected.
export 'ocr_stub.dart' if (dart.library.html) 'ocr_web.dart';
