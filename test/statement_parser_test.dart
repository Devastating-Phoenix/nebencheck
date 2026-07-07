import 'package:flutter_test/flutter_test.dart';
import 'package:nebencheck/logic/statement_parser.dart';

void main() {
  group('parseGermanAmount', () {
    final cases = <String, double?>{
      '168,00': 168.0,
      '168': 168.0,
      '1.234,56': 1234.56,
      '1.980,00': 1980.0,
      '1.980': 1980.0, // single dot + 3 digits = thousands
      '1.98': 1.98, // single dot + 2 digits = decimal
      '310,50': 310.5,
      '0,03': 0.03,
      '€168,00': 168.0,
      '168,00€': 168.0,
      '  25,00  ': 25.0,
      '12.345.678,90': 12345678.90,
      'abc': null,
      '': null,
    };
    cases.forEach((input, expected) {
      test('"$input" -> $expected', () {
        final got = StatementParser.parseGermanAmount(input);
        if (expected == null) {
          expect(got, isNull);
        } else {
          expect(got, closeTo(expected, 0.001));
        }
      });
    });
  });

  group('lastAmount picks the value at the end of a row', () {
    test('simple label + amount', () {
      expect(StatementParser.lastAmount('Grundsteuer 168,00 €'),
          closeTo(168.0, 0.001));
    });
    test('trailing euro sign and spaces', () {
      expect(StatementParser.lastAmount('Wasser/Abwasser        310,00'),
          closeTo(310.0, 0.001));
    });
    test('leading position number is ignored, amount wins', () {
      expect(StatementParser.lastAmount('3  Heizung  1.020,00 €'),
          closeTo(1020.0, 0.001));
    });
    test('no amount', () {
      expect(StatementParser.lastAmount('Betriebskostenabrechnung'), isNull);
    });
  });

  group('category matching and the tricky overlaps', () {
    ParsedStatement p(String s) => StatementParser.parse(s);

    test('Warmwasser is not swallowed by Wasser', () {
      final r = p('Warmwasser 210,00 €\nWasser/Abwasser 310,00 €');
      expect(r.amounts['warmwasser'], closeTo(210.0, 0.001));
      expect(r.amounts['wasser'], closeTo(310.0, 0.001));
    });

    test('Straßenreinigung vs Gebäudereinigung vs bare Reinigung', () {
      final r = p('Straßenreinigung 25,00\nGebäudereinigung 260,00');
      expect(r.amounts['strassenreinigung'], closeTo(25.0, 0.001));
      expect(r.amounts['reinigung'], closeTo(260.0, 0.001));
    });

    test('umlaut-free OCR (ae/oe/ue) still matches', () {
      final r = p('Muellbeseitigung 165,00\nGebaeudereinigung 260,00');
      expect(r.amounts['muell'], closeTo(165.0, 0.001));
      expect(r.amounts['reinigung'], closeTo(260.0, 0.001));
    });

    test('common categories map to the right ids', () {
      final r = p('Grundsteuer 168,00\n'
          'Allgemeinstrom / Beleuchtung 55,00\n'
          'Hauswart 340,00\n'
          'Sach- und Haftpflichtversicherung 230,00\n'
          'Schornsteinfeger 25,00\n'
          'Aufzug 90,00');
      expect(r.amounts['grundsteuer'], closeTo(168.0, 0.001));
      expect(r.amounts['strom'], closeTo(55.0, 0.001));
      expect(r.amounts['hauswart'], closeTo(340.0, 0.001));
      expect(r.amounts['versicherung'], closeTo(230.0, 0.001));
      expect(r.amounts['schornstein'], closeTo(25.0, 0.001));
      expect(r.amounts['aufzug'], closeTo(90.0, 0.001));
    });

    test('summary / total lines are never read as a position', () {
      final r = p('Gesamtsumme 2.963,00 €\n'
          'Summe Betriebskosten 2.963,00\n'
          'Nachzahlung 983,00 €');
      expect(r.amounts, isEmpty);
    });

    test('label on one row, amount on the next row', () {
      final r = p('Grundsteuer\n168,00 €\nWasserversorgung\n310,00');
      expect(r.amounts['grundsteuer'], closeTo(168.0, 0.001));
      expect(r.amounts['wasser'], closeTo(310.0, 0.001));
    });

    test('a category with no readable amount is skipped, not guessed', () {
      final r = p('Gartenpflege\nHausordnung beachten');
      expect(r.amounts.containsKey('garten'), isFalse);
    });
  });

  group('apartment size', () {
    test('m² with colon', () {
      expect(StatementParser.parse('Wohnfläche: 62 m²').apartmentSize,
          closeTo(62.0, 0.001));
    });
    test('decimal qm', () {
      expect(StatementParser.parse('Wohnfläche 62,5 qm').apartmentSize,
          closeTo(62.5, 0.001));
    });
    test('m2 fallback spelling', () {
      expect(StatementParser.parse('Ihre Wohnung: 62 m2').apartmentSize,
          closeTo(62.0, 0.001));
    });
    test('OCR mangles "m²" into "m?" (real Tesseract behavior)', () {
      expect(StatementParser.parse('Wohnfläche: 62 m?').apartmentSize,
          closeTo(62.0, 0.001));
    });
    test('unit dropped entirely, size still read after the label', () {
      expect(StatementParser.parse('Wohnfläche der Wohnung Nr. 12: 62')
          .apartmentSize, closeTo(62.0, 0.001));
    });
    test('implausible size is rejected', () {
      expect(StatementParser.parse('Grundstück 2500 m²').apartmentSize, isNull);
    });
  });

  group('prepayments', () {
    test('Vorauszahlungen', () {
      expect(StatementParser.parse('Vorauszahlungen 1.980,00 €').prepaid,
          closeTo(1980.0, 0.001));
    });
    test('geleistete Vorauszahlungen with colon', () {
      expect(
          StatementParser.parse('Geleistete Vorauszahlungen: 1.980,00').prepaid,
          closeTo(1980.0, 0.001));
    });
  });

  group('billing period', () {
    test('Abrechnungszeitraum with dash', () {
      final r = StatementParser.parse(
          'Abrechnungszeitraum 01.01.2024 - 31.12.2024');
      expect(r.periodStart, DateTime(2024, 1, 1));
      expect(r.periodEnd, DateTime(2024, 12, 31));
    });
    test('Zeitraum with "bis" and single-digit day/month', () {
      final r = StatementParser.parse('Zeitraum: 1.1.2023 bis 31.12.2023');
      expect(r.periodStart, DateTime(2023, 1, 1));
      expect(r.periodEnd, DateTime(2023, 12, 31));
    });
    test('date range is detected even without a section keyword, and an '
        'earlier invoice date does not hijack it', () {
      final r = StatementParser.parse(
          'Rechnung vom 05.02.2025\nfür 01.01.2024 bis 31.12.2024');
      expect(r.periodStart, DateTime(2024, 1, 1));
      expect(r.periodEnd, DateTime(2024, 12, 31));
    });

    test('compact range with hyphen and no spaces', () {
      final r = StatementParser.parse('01.01.2024-31.12.2024');
      expect(r.periodStart, DateTime(2024, 1, 1));
      expect(r.periodEnd, DateTime(2024, 12, 31));
    });
  });

  group('full realistic statement', () {
    const ocr = '''
Hausverwaltung Schmidt GmbH
Betriebskostenabrechnung
Mieter: Max Mustermann
Wohnfläche: 62 m²
Abrechnungszeitraum 01.01.2024 - 31.12.2024

Pos  Kostenart                 Betrag
1    Grundsteuer               168,00 €
2    Wasser/Abwasser           310,00 €
3    Heizung                 1.020,00 €
4    Warmwasser                210,00 €
5    Müllbeseitigung           165,00 €
6    Gebäudereinigung          260,00 €
7    Allgemeinstrom             55,00 €
8    Schornsteinfeger           25,00 €
9    Gebäudeversicherung       230,00 €
10   Hauswart                  340,00 €

Gesamtsumme                  2.783,00 €
Geleistete Vorauszahlungen   1.980,00 €
Nachzahlung                    803,00 €
''';

    test('extracts every position, size, prepaid and period', () {
      final r = StatementParser.parse(ocr);
      expect(r.apartmentSize, closeTo(62.0, 0.001));
      expect(r.prepaid, closeTo(1980.0, 0.001));
      expect(r.periodStart, DateTime(2024, 1, 1));
      expect(r.periodEnd, DateTime(2024, 12, 31));
      expect(r.amounts['grundsteuer'], closeTo(168.0, 0.001));
      expect(r.amounts['wasser'], closeTo(310.0, 0.001));
      expect(r.amounts['heizung'], closeTo(1020.0, 0.001));
      expect(r.amounts['warmwasser'], closeTo(210.0, 0.001));
      expect(r.amounts['muell'], closeTo(165.0, 0.001));
      expect(r.amounts['reinigung'], closeTo(260.0, 0.001));
      expect(r.amounts['strom'], closeTo(55.0, 0.001));
      expect(r.amounts['schornstein'], closeTo(25.0, 0.001));
      expect(r.amounts['versicherung'], closeTo(230.0, 0.001));
      expect(r.amounts['hauswart'], closeTo(340.0, 0.001));
      // exactly the 10 positions, nothing from the summary block
      expect(r.amounts.length, 10);
    });
  });

  group('noise & robustness', () {
    test('mixed case, extra whitespace, tabs', () {
      final r = StatementParser.parse(
          'GRUNDSTEUER\t\t168,00  €\n   heizung     1.020,00');
      expect(r.amounts['grundsteuer'], closeTo(168.0, 0.001));
      expect(r.amounts['heizung'], closeTo(1020.0, 0.001));
    });

    test('empty input yields an empty result', () {
      final r = StatementParser.parse('');
      expect(r.isEmpty, isTrue);
      expect(r.fieldCount, 0);
    });

    test('pure garbage yields an empty result', () {
      final r = StatementParser.parse('==== ~~~~ \n |||| \n .... ');
      expect(r.amounts, isEmpty);
      expect(r.apartmentSize, isNull);
    });
  });

  // The exact text Tesseract produced when run on a rendered German statement
  // in the browser (captured during integration testing). Locks in that the
  // parser survives real OCR output — including the "m²" -> "m?" corruption.
  group('real Tesseract OCR output end-to-end', () {
    const ocr = 'Hausverwaltung Schmidt GmbH\n'
        'Betriebskostenabrechnung 2024\n'
        'Wohnfläche: 62 m?\n'
        'Abrechnungszeitraum 01.01.2024 - 31.12.2024\n'
        'Grundsteuer 168,00\n'
        'Wasser/Abwasser 310,00\n'
        'Heizung 1.020,00\n'
        'Warmwasser 210,00\n'
        'Müllbeseitigung 165,00\n'
        'Gebäudereinigung 260,00\n'
        'Allgemeinstrom 55,00\n'
        'Gebäudeversicherung 230,00\n'
        'Hauswart 340,00\n'
        'Vorauszahlungen 1.980,00\n';

    test('every field is recovered from the real OCR text', () {
      final r = StatementParser.parse(ocr);
      expect(r.apartmentSize, closeTo(62.0, 0.001));
      expect(r.prepaid, closeTo(1980.0, 0.001));
      expect(r.periodStart, DateTime(2024, 1, 1));
      expect(r.periodEnd, DateTime(2024, 12, 31));
      expect(r.amounts, {
        'grundsteuer': 168.0,
        'wasser': 310.0,
        'heizung': 1020.0,
        'warmwasser': 210.0,
        'muell': 165.0,
        'reinigung': 260.0,
        'strom': 55.0,
        'versicherung': 230.0,
        'hauswart': 340.0,
      });
    });
  });
}
