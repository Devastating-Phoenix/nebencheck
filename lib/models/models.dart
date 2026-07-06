/// Core domain models. Kept free of Flutter imports so the analyzer and the
/// letter generator can run as plain Dart (fast, headless unit tests).
library;

/// One of the operating-cost categories a German landlord may bill
/// (Betriebskostenverordnung, § 2 BetrKV).
class CostCategory {
  final String id;
  final String nameDe;
  final String nameEn;

  /// National reference value in € per m² per month
  /// (approximation of the Deutscher Mieterbund Betriebskostenspiegel).
  final double benchmark;

  final String hint;
  final String hintDe;

  const CostCategory({
    required this.id,
    required this.nameDe,
    required this.nameEn,
    required this.benchmark,
    this.hint = '',
    this.hintDe = '',
  });
}

/// The tenant's entry for one predefined category.
class CostEntry {
  final CostCategory category;
  bool included;

  /// Amount billed for the whole statement period, in €.
  double amount;

  CostEntry({required this.category, this.included = false, this.amount = 0});
}

/// A free-text line item on the statement, e.g. "Verwaltungskosten 180 €".
class CustomItem {
  String name;
  double amount;

  CustomItem({this.name = '', this.amount = 0});
}

/// Everything the user copied in from their paper statement.
class StatementData {
  double apartmentSize; // m²
  DateTime periodStart;
  DateTime periodEnd;
  DateTime receivedDate;
  double prepaid; // Vorauszahlungen over the period, in €
  String tenantName;
  String landlordName;

  /// City the flat is in (see `data/cities.dart`). Scales the reference
  /// values to the regional cost level; 'de' = national average.
  String cityId;

  /// How heating is billed: 'unknown' (default), 'consumption'
  /// (≥50% by actual consumption, as the Heizkostenverordnung requires)
  /// or 'flat' (flat rate only → 15% cut right, § 12 HeizKV).
  String heatingBilling;

  List<CostEntry> entries;
  List<CustomItem> customItems;

  StatementData({
    required this.apartmentSize,
    required this.periodStart,
    required this.periodEnd,
    required this.receivedDate,
    required this.prepaid,
    this.tenantName = '',
    this.landlordName = '',
    this.cityId = 'de',
    this.heatingBilling = 'unknown',
    required this.entries,
    required this.customItems,
  });
}

/// Verdict for a single billed position.
enum Verdict { ok, elevated, high, notApportionable }

/// Result of checking one position against the benchmark and the law.
class PositionResult {
  final String name;
  final double amount; // € for the whole period
  final double perSqmMonth; // €/m²/month
  final double benchmark; // €/m²/month reference (0 = no comparison)
  final double ratio; // perSqmMonth / benchmark
  final Verdict verdict;

  /// € above the benchmark for the whole period (only for flagged items).
  final double excess;

  /// English explanation shown in the app.
  final String note;

  /// German sentence reused in the objection letter.
  final String letterReason;

  const PositionResult({
    required this.name,
    required this.amount,
    required this.perSqmMonth,
    required this.benchmark,
    required this.ratio,
    required this.verdict,
    required this.excess,
    required this.note,
    required this.letterReason,
  });
}

/// Status of a formal / legal check.
enum CheckStatus { passed, failed, info }

class FormalCheck {
  final String title;
  final String detail;
  final CheckStatus status;

  const FormalCheck({
    required this.title,
    required this.detail,
    required this.status,
  });
}

/// Full report produced by the analyzer.
class AnalysisReport {
  final List<PositionResult> positions;
  final List<FormalCheck> checks;
  final double months; // length of the billing period
  final double totalCosts; // € billed in total
  final double totalPerSqmMonth;
  final double benchmarkPerSqmMonth; // sum of benchmarks for billed categories
  final double balance; // totalCosts - prepaid (positive = back payment)
  final double potentialSavings; // € worth objecting to
  final bool lateDelivery;
  final DateTime deliveryDeadline;
  final DateTime objectionDeadline;
  final int score; // 5-100, higher = cleaner statement

  /// € the tenant may cut from heating under § 12 HeizKV
  /// (0 when heating is billed by consumption or unknown).
  final double heatingCut;

  const AnalysisReport({
    required this.positions,
    required this.checks,
    required this.months,
    required this.totalCosts,
    required this.totalPerSqmMonth,
    required this.benchmarkPerSqmMonth,
    required this.balance,
    required this.potentialSavings,
    required this.lateDelivery,
    required this.deliveryDeadline,
    required this.objectionDeadline,
    required this.score,
    this.heatingCut = 0,
  });

  bool get hasFindings => positions.any((p) => p.verdict != Verdict.ok);
}
