/// Non-web fallback: statement import only runs in the browser.
bool get ocrAvailable => false;

Future<String?> pickAndRecognize({
  void Function(double progress)? onProgress,
}) async =>
    null;

Future<String?> pickAndReadDocument({
  void Function(double progress)? onProgress,
}) async =>
    null;
