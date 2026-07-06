import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../data/samples.dart';
import '../logic/analyzer.dart';
import '../logic/storage.dart';
import '../models/models.dart';
import '../util/l10n.dart';

/// Single source of truth for the current check.
///
/// Finished checks and the UI language are persisted to the browser's
/// local storage so they survive a refresh or a closed tab.
class AppState extends ChangeNotifier {
  StatementData draft = Samples.empty();
  AnalysisReport? report;

  /// Past checks, newest first. Loaded asynchronously at startup.
  List<CheckSummary> history = [];

  AppState() {
    _restore();
  }

  Future<void> _restore() async {
    final saved = await Storage.loadLang();
    AppLang.code = saved ??
        (ui.PlatformDispatcher.instance.locale.languageCode == 'de'
            ? 'de'
            : 'en');
    history = await Storage.loadHistory();
    notifyListeners();
  }

  /// Switches the UI language, persists it and — if a report is open —
  /// re-runs the analysis so its notes switch language too. Re-analysis
  /// deliberately bypasses [analyze] so it is not recorded twice.
  void setLang(String code) {
    if (AppLang.code == code) return;
    AppLang.code = code;
    Storage.saveLang(code);
    if (report != null) {
      report = Analyzer.analyze(draft);
    }
    notifyListeners();
  }

  /// Starts a fresh, blank check.
  void startNew() {
    draft = Samples.empty();
    report = null;
    notifyListeners();
  }

  /// Loads the built-in demo statement and analyzes it immediately.
  /// Demo runs are not saved to history.
  void loadDemo() {
    draft = Samples.demo();
    report = Analyzer.analyze(draft);
    notifyListeners();
  }

  /// Runs the analyzer on the current draft and records the check.
  void analyze() {
    final r = Analyzer.analyze(draft);
    report = r;
    final now = DateTime.now();
    history.insert(
      0,
      CheckSummary(
        id: now.millisecondsSinceEpoch,
        savedAt: now,
        cityId: draft.cityId,
        score: r.score,
        savings: r.potentialSavings,
        statement: Storage.statementToJson(draft),
      ),
    );
    if (history.length > Storage.maxEntries) {
      history = history.sublist(0, Storage.maxEntries);
    }
    Storage.saveHistory(history);
    notifyListeners();
  }

  /// Reopens a saved check: restores the statement and re-analyzes it.
  void openSaved(CheckSummary saved) {
    draft = Storage.statementFromJson(saved.statement);
    report = Analyzer.analyze(draft);
    notifyListeners();
  }

  /// Clears all saved checks from this browser.
  void clearHistory() {
    history = [];
    Storage.saveHistory(history);
    notifyListeners();
  }
}
