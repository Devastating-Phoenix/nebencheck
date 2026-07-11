/// Platform door for browser downloads and external links.
/// On web this maps to Blob downloads and window.open; elsewhere the
/// stub throws (the app currently ships as web only).
library;

export 'save_file_stub.dart' if (dart.library.html) 'save_file_web.dart';
