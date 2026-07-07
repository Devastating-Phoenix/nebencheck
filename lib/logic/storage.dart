import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/benchmarks.dart';
import '../models/models.dart';

/// One finished check, kept so the user can reopen it later.
///
/// The full statement is stored, not just the result, so a saved check
/// can be re-analyzed (and will even pick up newer reference values).
class CheckSummary {
  final int id; // epoch ms, doubles as sort key
  final DateTime savedAt;
  final String cityId;
  final int score;
  final double savings;
  final Map<String, dynamic> statement;

  const CheckSummary({
    required this.id,
    required this.savedAt,
    required this.cityId,
    required this.score,
    required this.savings,
    required this.statement,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'savedAt': savedAt.toIso8601String(),
        'cityId': cityId,
        'score': score,
        'savings': savings,
        'statement': statement,
      };

  static CheckSummary fromJson(Map<String, dynamic> j) => CheckSummary(
        id: (j['id'] as num).toInt(),
        savedAt: DateTime.parse(j['savedAt'] as String),
        cityId: (j['cityId'] as String?) ?? 'de',
        score: (j['score'] as num).toInt(),
        savings: (j['savings'] as num).toDouble(),
        statement: Map<String, dynamic>.from(j['statement'] as Map),
      );
}

/// Persists checks in the browser's local storage (shared_preferences
/// maps to window.localStorage on web). Data never leaves the device.
class Storage {
  static const _historyKey = 'nc_history_v1';
  static const maxEntries = 8;

  static Map<String, dynamic> statementToJson(StatementData d) => {
        'size': d.apartmentSize,
        'start': d.periodStart.toIso8601String(),
        'end': d.periodEnd.toIso8601String(),
        'received': d.receivedDate.toIso8601String(),
        'prepaid': d.prepaid,
        // Privacy: tenant/landlord names are deliberately NOT persisted to the
        // device. They live only in memory for the current session's letter.
        'cityId': d.cityId,
        'heating': d.heatingBilling,
        'entries': {
          for (final e in d.entries)
            if (e.included || e.amount > 0)
              e.category.id: {'included': e.included, 'amount': e.amount},
        },
        'custom': [
          for (final c in d.customItems)
            if (c.name.isNotEmpty || c.amount > 0)
              {'name': c.name, 'amount': c.amount},
        ],
      };

  static StatementData statementFromJson(Map<String, dynamic> j) {
    final saved = Map<String, dynamic>.from(j['entries'] as Map? ?? {});
    return StatementData(
      apartmentSize: (j['size'] as num?)?.toDouble() ?? 0,
      periodStart: DateTime.parse(j['start'] as String),
      periodEnd: DateTime.parse(j['end'] as String),
      receivedDate: DateTime.parse(j['received'] as String),
      prepaid: (j['prepaid'] as num?)?.toDouble() ?? 0,
      tenantName: (j['tenant'] as String?) ?? '',
      landlordName: (j['landlord'] as String?) ?? '',
      cityId: (j['cityId'] as String?) ?? 'de',
      heatingBilling: (j['heating'] as String?) ?? 'unknown',
      entries: [
        for (final c in kCategories)
          CostEntry(
            category: c,
            included:
                (saved[c.id] as Map?)?['included'] as bool? ?? false,
            amount:
                ((saved[c.id] as Map?)?['amount'] as num?)?.toDouble() ?? 0,
          ),
      ],
      customItems: [
        for (final c in (j['custom'] as List? ?? []))
          CustomItem(
            name: (c['name'] as String?) ?? '',
            amount: (c['amount'] as num?)?.toDouble() ?? 0,
          ),
      ],
    );
  }

  /// Strips tenant/landlord names from a stored entry (cleans data written by
  /// older versions that used to persist them).
  static Map<String, dynamic> _scrubNames(Map<String, dynamic> entry) {
    final stmt = entry['statement'];
    if (stmt is Map) {
      stmt.remove('tenant');
      stmt.remove('landlord');
    }
    return entry;
  }

  static Future<List<CheckSummary>> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_historyKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List;
      final history = [
        for (final e in list)
          CheckSummary.fromJson(_scrubNames(Map<String, dynamic>.from(e as Map))),
      ];
      // One-time cleanup: rewrite storage so any names saved by older versions
      // are actually removed from the device, not merely hidden from the UI.
      unawaited(saveHistory(history));
      return history;
    } catch (_) {
      // Corrupt or legacy data: start fresh rather than crash the app.
      return [];
    }
  }

  static Future<void> saveHistory(List<CheckSummary> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _historyKey,
      jsonEncode([for (final h in history) h.toJson()]),
    );
  }

  static const _langKey = 'nc_lang';

  static Future<String?> loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_langKey);
  }

  static Future<void> saveLang(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, code);
  }
}
