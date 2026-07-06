// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// The canonical reference file, served from the repository's `main` branch.
/// A merged pull request to `references.json` goes live here within minutes —
/// no app rebuild or redeploy needed.
const _referencesUrl =
    'https://raw.githubusercontent.com/Devastating-Phoenix/nebencheck/main/references.json';

Future<String?> fetchReferences() async {
  try {
    return await html.HttpRequest.getString(_referencesUrl);
  } catch (_) {
    return null; // offline / blocked / 404 → caller keeps compiled defaults
  }
}
