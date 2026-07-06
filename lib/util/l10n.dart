/// Ultra-light two-language support, deliberately free of Flutter
/// imports so the analyzer and letter generator (pure Dart) can use it.
///
/// [AppLang.code] is a process-wide setting owned by AppState, which
/// persists it and rebuilds the widget tree on change. The objection
/// letter itself is always German regardless of the UI language — it is
/// addressed to a German landlord.
class AppLang {
  static String code = 'en';

  static bool get isDe => code == 'de';
}

/// Returns [de] when the UI language is German, otherwise [en].
String tr(String en, String de) => AppLang.isDe ? de : en;
