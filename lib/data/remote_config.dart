import 'dart:convert';

import 'cities.dart';
import 'remote_fetch.dart';

/// Runtime overrides for the reference values and city factors, fetched from
/// `references.json` at startup. Everything falls back to the compiled-in
/// defaults in `benchmarks.dart` / `cities.dart`, so a failed fetch, a
/// missing key, or a malformed file can never break the audit — it just runs
/// on the bundled data. See [load].
class RemoteConfig {
  static final RemoteConfig instance = RemoteConfig._();
  RemoteConfig._();

  Map<String, double> _national = const {};
  Map<String, ({double service, double fee})> _cities = const {};

  bool loaded = false;
  String? dataYear;

  /// Fetches and parses the reference file. Never throws.
  Future<void> load() async {
    try {
      final text = await fetchReferences();
      if (text == null || text.isEmpty) return;
      final j = jsonDecode(text) as Map<String, dynamic>;

      final nat = <String, double>{};
      (j['national'] as Map?)?.forEach((k, v) {
        if (v is num) nat['$k'] = v.toDouble();
      });

      final cities = <String, ({double service, double fee})>{};
      (j['cities'] as Map?)?.forEach((k, v) {
        if (v is Map && v['service'] is num && v['fee'] is num) {
          cities['$k'] = (
            service: (v['service'] as num).toDouble(),
            fee: (v['fee'] as num).toDouble(),
          );
        }
      });

      _national = nat;
      _cities = cities;
      dataYear = j['dataYear'] as String?;
      loaded = true;
    } catch (_) {
      // Malformed or unreachable — keep whatever we had (compiled defaults).
    }
  }

  /// National €/m²/month value for [categoryId], or [fallback] (the compiled
  /// `CostCategory.benchmark`) when no override is present.
  double nat(String categoryId, double fallback) =>
      _national[categoryId] ?? fallback;

  double serviceFactor(City c) => _cities[c.id]?.service ?? c.serviceFactor;
  double feeFactor(City c) => _cities[c.id]?.fee ?? c.feeFactor;

  /// The factor to apply to [categoryId] for [city], mirroring
  /// [City.factorFor] but drawing on any runtime overrides.
  double factorFor(City city, String categoryId) {
    if (City.feeCategories.contains(categoryId)) return feeFactor(city);
    if (City.nationalCategories.contains(categoryId)) return 1.0;
    return serviceFactor(city);
  }
}
