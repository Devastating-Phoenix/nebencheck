import 'package:flutter_test/flutter_test.dart';
import 'package:nebencheck/data/benchmarks.dart';
import 'package:nebencheck/logic/analyzer.dart';
import 'package:nebencheck/logic/letter_generator.dart';
import 'package:nebencheck/models/models.dart';

void main() {
  final grundsteuer = kCategories.firstWhere((c) => c.id == 'grundsteuer');
  final heizung = kCategories.firstWhere((c) => c.id == 'heizung');

  StatementData base({
    DateTime? received,
    String tenant = '',
    String landlord = '',
    double grundsteuerAmount = 300,
    List<CustomItem>? customItems,
    HeatingBilling heating = HeatingBilling.unknown,
    List<CostEntry>? entries,
  }) {
    return StatementData(
      apartmentSize: 60,
      periodStart: DateTime(2024, 1, 1),
      periodEnd: DateTime(2024, 12, 31),
      receivedDate: received ?? DateTime(2025, 5, 10),
      prepaid: 100,
      tenantName: tenant,
      landlordName: landlord,
      heatingBilling: heating,
      entries: entries ??
          [
            CostEntry(
                category: grundsteuer, included: true, amount: grundsteuerAmount)
          ],
      customItems:
          customItems ?? [CustomItem(name: 'Verwaltungskosten', amount: 100)],
    );
  }

  String letterFor(StatementData data) =>
      LetterGenerator.build(data, Analyzer.analyze(data));

  test('subject line carries the billing period, body the received date', () {
    final letter = letterFor(base());
    expect(
        letter,
        contains('Widerspruch gegen die Betriebskostenabrechnung – '
            'Abrechnungszeitraum 01.01.2024 bis 31.12.2024'));
    expect(letter, contains('am 10.05.2025 zugegangen'));
    expect(letter, contains('§ 556 Abs. 3 Satz 5 BGB'));
  });

  test('missing names become placeholders, never empty lines', () {
    final letter = letterFor(base());
    expect(letter, contains('[Ihr Name]'));
    expect(letter, contains('[Vermieter / Hausverwaltung]'));
  });

  test('provided names replace the placeholders everywhere', () {
    final letter = letterFor(
        base(tenant: 'Max Mustermann', landlord: 'Hausverwaltung Schmidt'));
    expect(letter, contains('Max Mustermann'));
    expect(letter, contains('Hausverwaltung Schmidt'));
    expect(letter, isNot(contains('[Ihr Name]')));
    expect(letter, isNot(contains('[Vermieter / Hausverwaltung]')));
  });

  test('flagged positions are itemized with their legal reason', () {
    final letter = letterFor(base());
    // Grundsteuer 300 € on 60 m² is far above benchmark -> listed.
    expect(letter, contains('Im Einzelnen bestehen Einwände'));
    expect(letter, contains('Grundsteuer'));
    // Admin costs are non-apportionable -> listed with § 1 Abs. 2 BetrKV.
    expect(letter, contains('Verwaltungskosten'));
    expect(letter, contains('§ 1 Abs. 2 BetrKV'));
    // Receipt inspection is always requested.
    expect(letter, contains('§ 259 BGB'));
  });

  test('a clean statement asks for receipts but lists no objections', () {
    // 100 € Grundsteuer on 60 m²/12 months is well inside the benchmark.
    final letter =
        letterFor(base(grundsteuerAmount: 100, customItems: []));
    expect(letter, isNot(contains('Im Einzelnen bestehen Einwände')));
    expect(letter, contains('Zur Prüfung der Abrechnung'));
    expect(letter, contains('§ 259 BGB'));
  });

  test('late delivery invokes § 556 Abs. 3 Satz 3 BGB with the deadline', () {
    final letter = letterFor(base(received: DateTime(2026, 3, 1)));
    expect(letter, contains('§ 556 Abs. 3 Satz 3 BGB'));
    // Deadline = period end + 12 months.
    expect(letter, contains('Fristende: 31.12.2025'));
  });

  test('an on-time statement never claims late delivery', () {
    final letter = letterFor(base());
    expect(letter, isNot(contains('§ 556 Abs. 3 Satz 3 BGB')));
  });

  test('flat-rate heating claims the 15% cut with the exact amount', () {
    final letter = letterFor(base(
      heating: HeatingBilling.flat,
      entries: [CostEntry(category: heizung, included: true, amount: 1000)],
      customItems: [],
    ));
    expect(letter, contains('§ 12 Abs. 1 HeizKV'));
    expect(letter, contains('150,00 €'));
  });

  test('consumption-billed heating claims no cut', () {
    final letter = letterFor(base(
      heating: HeatingBilling.consumption,
      entries: [CostEntry(category: heizung, included: true, amount: 1000)],
      customItems: [],
    ));
    expect(letter, isNot(contains('§ 12 Abs. 1 HeizKV')));
  });
}
