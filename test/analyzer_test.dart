import 'package:flutter_test/flutter_test.dart';
import 'package:nebencheck/data/benchmarks.dart';
import 'package:nebencheck/logic/analyzer.dart';
import 'package:nebencheck/models/models.dart';

void main() {
  StatementData base({DateTime? received}) {
    final grundsteuer = kCategories.firstWhere((c) => c.id == 'grundsteuer');
    return StatementData(
      apartmentSize: 60,
      periodStart: DateTime(2024, 1, 1),
      periodEnd: DateTime(2024, 12, 31),
      receivedDate: received ?? DateTime(2025, 5, 10),
      prepaid: 100,
      entries: [CostEntry(category: grundsteuer, included: true, amount: 300)],
      customItems: [CustomItem(name: 'Verwaltungskosten', amount: 100)],
    );
  }

  test('flags positions far above the benchmark', () {
    final report = Analyzer.analyze(base());
    final grund =
        report.positions.firstWhere((p) => p.name.contains('Grundsteuer'));
    // 300 € on 60 m² over ~12 months is ~0.42 €/m²·mo vs 0.19 benchmark.
    expect(grund.verdict, Verdict.high);
    expect(report.potentialSavings, greaterThan(100));
  });

  test('flags non-apportionable admin costs (§ 1 Abs. 2 BetrKV)', () {
    final report = Analyzer.analyze(base());
    final admin =
        report.positions.firstWhere((p) => p.name == 'Verwaltungskosten');
    expect(admin.verdict, Verdict.notApportionable);
    expect(admin.excess, 100);
  });

  test('detects a late statement (§ 556 Abs. 3 BGB)', () {
    final report = Analyzer.analyze(base(received: DateTime(2026, 3, 1)));
    expect(report.lateDelivery, isTrue);
    expect(report.score, lessThan(60));
  });

  test('an on-time statement passes the deadline check', () {
    final report = Analyzer.analyze(base());
    expect(report.lateDelivery, isFalse);
  });

  test('flat-rate heating triggers the 15% cut (§ 12 HeizKV)', () {
    final heizung = kCategories.firstWhere((c) => c.id == 'heizung');
    StatementData withHeating(String billing) => StatementData(
          apartmentSize: 60,
          periodStart: DateTime(2024, 1, 1),
          periodEnd: DateTime(2024, 12, 31),
          receivedDate: DateTime(2025, 5, 10),
          prepaid: 100,
          heatingBilling: billing,
          entries: [CostEntry(category: heizung, included: true, amount: 1000)],
          customItems: [],
        );

    final flat = Analyzer.analyze(withHeating('flat'));
    final consumption = Analyzer.analyze(withHeating('consumption'));

    expect(flat.heatingCut, closeTo(150, 0.01));
    expect(flat.potentialSavings,
        greaterThanOrEqualTo(consumption.potentialSavings + 150));
    expect(flat.score, lessThan(consumption.score));
    expect(consumption.heatingCut, 0);
  });

  test('fee and service categories scale by different city factors', () {
    StatementData withCity(String cityId, CostCategory cat, double amount) =>
        StatementData(
          apartmentSize: 60,
          periodStart: DateTime(2024, 1, 1),
          periodEnd: DateTime(2024, 12, 31),
          receivedDate: DateTime(2025, 5, 10),
          prepaid: 100,
          cityId: cityId,
          entries: [CostEntry(category: cat, included: true, amount: amount)],
          customItems: [],
        );

    final wasser = kCategories.firstWhere((c) => c.id == 'wasser');
    final hauswart = kCategories.firstWhere((c) => c.id == 'hauswart');

    // Water is a MUNICIPAL FEE. Munich's fees are among the cheapest in
    // the country (feeFactor 0.81), so the same water bill is judged more
    // strictly there than nationally — the opposite of naïve "Munich is
    // expensive" reasoning.
    final waterNat = Analyzer.analyze(withCity('de', wasser, 320));
    final waterMuc = Analyzer.analyze(withCity('muenchen', wasser, 320));
    expect(waterMuc.positions.single.benchmark,
        lessThan(waterNat.positions.single.benchmark));
    expect(waterMuc.positions.single.ratio,
        greaterThan(waterNat.positions.single.ratio));

    // Caretaker is a SERVICE. Leipzig's service wages are low
    // (serviceFactor 0.83), so its reference is below the national one.
    final careNat = Analyzer.analyze(withCity('de', hauswart, 300));
    final careLeip = Analyzer.analyze(withCity('leipzig', hauswart, 300));
    expect(careLeip.positions.single.benchmark,
        lessThan(careNat.positions.single.benchmark));
  });

  test('heating reference is national and never scales by city', () {
    final heizung = kCategories.firstWhere((c) => c.id == 'heizung');
    StatementData withCity(String cityId) => StatementData(
          apartmentSize: 60,
          periodStart: DateTime(2024, 1, 1),
          periodEnd: DateTime(2024, 12, 31),
          receivedDate: DateTime(2025, 5, 10),
          prepaid: 100,
          cityId: cityId,
          entries: [CostEntry(category: heizung, included: true, amount: 900)],
          customItems: [],
        );

    final nat = Analyzer.analyze(withCity('de')).positions.single;
    final muc = Analyzer.analyze(withCity('muenchen')).positions.single;
    final ber = Analyzer.analyze(withCity('berlin')).positions.single;
    expect(muc.benchmark, nat.benchmark);
    expect(ber.benchmark, nat.benchmark);
  });
}
