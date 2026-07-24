import 'package:flutter_test/flutter_test.dart';
import 'package:nebencheck/util/format.dart';

void main() {
  group('fmtEuro (German convention)', () {
    test('groups thousands with dots, decimals with comma', () {
      expect(fmtEuro(1234.56), '1.234,56 €');
      expect(fmtEuro(12345678.9), '12.345.678,90 €');
    });
    test('no grouping below 1000', () {
      expect(fmtEuro(999.99), '999,99 €');
      expect(fmtEuro(0), '0,00 €');
    });
    test('negative amounts keep the sign in front', () {
      expect(fmtEuro(-1234.5), '-1.234,50 €');
    });
    test('rounds to the requested decimals', () {
      expect(fmtEuro(150.456), '150,46 €');
      expect(fmtEuro(150, decimals: 0), '150 €');
    });
  });

  group('fmtDate (dd.MM.yyyy)', () {
    test('pads day and month', () {
      expect(fmtDate(DateTime(2024, 1, 5)), '05.01.2024');
    });
    test('two-digit day and month unchanged', () {
      expect(fmtDate(DateTime(2025, 12, 31)), '31.12.2025');
    });
  });

  group('parseAmount (user input, German or English style)', () {
    test('German style with thousands dot', () {
      expect(parseAmount('1.234,56'), closeTo(1234.56, 0.001));
    });
    test('English style', () {
      expect(parseAmount('1234.56'), closeTo(1234.56, 0.001));
    });
    test('euro sign and spaces are stripped', () {
      expect(parseAmount(' € 25,00 '), closeTo(25.0, 0.001));
    });
    test('empty and garbage input fall back to 0', () {
      expect(parseAmount(''), 0);
      expect(parseAmount('abc'), 0);
    });
  });

  group('addMonths (calendar-safe)', () {
    test('31 Jan + 1 month clamps to end of February', () {
      expect(addMonths(DateTime(2025, 1, 31), 1), DateTime(2025, 2, 28));
    });
    test('leap year February keeps the 29th', () {
      expect(addMonths(DateTime(2024, 1, 31), 1), DateTime(2024, 2, 29));
    });
    test('31 May + 1 month clamps to 30 June', () {
      expect(addMonths(DateTime(2024, 5, 31), 1), DateTime(2024, 6, 30));
    });
    test('crosses a year boundary', () {
      expect(addMonths(DateTime(2024, 12, 15), 1), DateTime(2025, 1, 15));
    });
    test('+12 months is the same day next year (the § 556 deadline rule)', () {
      expect(addMonths(DateTime(2024, 12, 31), 12), DateTime(2025, 12, 31));
    });
  });
}
