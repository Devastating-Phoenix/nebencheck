// TODO(migration): move to package:web + dart:js_interop once the pinned
// Flutter SDK is bumped; dart:html still works but is deprecated.
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

/// The canonical reference file. Served same-origin: a Vercel rewrite
/// (web/vercel.json) proxies this path to the repository's `main` branch, so
/// a merged pull request to `references.json` still goes live within minutes
/// with no rebuild — but the user's browser only ever talks to the app's own
/// origin (DSGVO: no user IP reaches GitHub). In local dev there is no proxy,
/// so the fetch 404s and the app runs on its compiled-in defaults.
const _referencesUrl = 'references.json';

Future<String?> fetchReferences() async {
  try {
    return await html.HttpRequest.getString(_referencesUrl);
  } catch (_) {
    return null; // offline / blocked / 404 → caller keeps compiled defaults
  }
}
