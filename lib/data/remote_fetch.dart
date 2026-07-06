/// Platform door for fetching the runtime reference file. On web this uses
/// an HTTP GET; on the Dart VM (unit tests) the stub returns null so the app
/// falls back to its compiled-in defaults.
export 'remote_fetch_stub.dart' if (dart.library.html) 'remote_fetch_web.dart';
