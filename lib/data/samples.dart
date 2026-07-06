import '../models/models.dart';
import 'benchmarks.dart';

/// Factories for a fresh, empty statement and a realistic demo statement.
class Samples {
  /// A blank check, defaulting to the most recent full calendar year.
  static StatementData empty() {
    final now = DateTime.now();
    final year = now.month >= 4 ? now.year - 1 : now.year - 2;
    return StatementData(
      apartmentSize: 0,
      periodStart: DateTime(year, 1, 1),
      periodEnd: DateTime(year, 12, 31),
      receivedDate: DateTime(now.year, now.month, now.day),
      prepaid: 0,
      entries: [
        for (final c in kCategories)
          CostEntry(category: c, included: kDefaultIncluded.contains(c.id)),
      ],
      customItems: [],
    );
  }

  /// A realistic 62 m² flat with several problems hidden inside:
  /// cleaning and caretaker far above average, elevated water and heating,
  /// and a non-apportionable "Verwaltungskosten" line.
  ///
  /// Dates are derived from the current clock so the demo always shows an
  /// on-time statement with an open objection window, no matter when it runs.
  static StatementData demo() {
    final now = DateTime.now();
    final received =
        DateTime(now.year, now.month, now.day).subtract(const Duration(days: 20));
    final periodEnd = received.subtract(const Duration(days: 150));
    final periodStart = periodEnd.subtract(const Duration(days: 364));

    const amounts = <String, double>{
      'grundsteuer': 168,
      'wasser': 310,
      'heizung': 1020,
      'warmwasser': 210,
      'muell': 165,
      'reinigung': 260,
      'strom': 55,
      'schornstein': 25,
      'versicherung': 230,
      'hauswart': 340,
    };

    return StatementData(
      apartmentSize: 62,
      periodStart: periodStart,
      periodEnd: periodEnd,
      receivedDate: received,
      prepaid: 1980,
      tenantName: 'Max Mustermann',
      landlordName: 'Hausverwaltung Schmidt GmbH',
      cityId: 'berlin',
      entries: [
        for (final c in kCategories)
          CostEntry(
            category: c,
            included: amounts.containsKey(c.id),
            amount: amounts[c.id] ?? 0,
          ),
      ],
      customItems: [CustomItem(name: 'Verwaltungskosten', amount: 180)],
    );
  }
}
