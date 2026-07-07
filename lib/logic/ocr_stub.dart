/// Non-web fallback: OCR only runs in the browser.
bool get ocrAvailable => false;

Future<String?> pickAndRecognize({
  void Function(double progress)? onProgress,
}) async =>
    null;
