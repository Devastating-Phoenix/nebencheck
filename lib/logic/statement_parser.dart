/// Turns raw OCR text from a scanned Nebenkostenabrechnung into a partial
/// [ParsedStatement]: apartment size, prepayments, billing period, and a
/// map of cost-category id → euro amount.
///
/// Pure Dart, no Flutter imports, so it runs headless under `flutter test`.
/// The output is always a *draft to be reviewed* — OCR is imperfect, so the
/// UI prefills the form and lets the user correct it. This parser's job is
/// recall (surface what it can) without inventing values it isn't sure of.
library;

class ParsedStatement {
  final double? apartmentSize; // m²
  final double? prepaid; // Vorauszahlungen, €
  final DateTime? periodStart;
  final DateTime? periodEnd;

  /// Cost-category id → amount for the whole period, €.
  final Map<String, double> amounts;

  const ParsedStatement({
    this.apartmentSize,
    this.prepaid,
    this.periodStart,
    this.periodEnd,
    this.amounts = const {},
  });

  bool get isEmpty =>
      apartmentSize == null &&
      prepaid == null &&
      periodStart == null &&
      periodEnd == null &&
      amounts.isEmpty;

  int get fieldCount =>
      amounts.length +
      (apartmentSize != null ? 1 : 0) +
      (prepaid != null ? 1 : 0) +
      (periodStart != null ? 1 : 0) +
      (periodEnd != null ? 1 : 0);
}

/// Category aliases in **priority order**: more specific / compound labels
/// come before generic ones so that, e.g., "Warmwasser" is claimed before a
/// bare "Wasser" rule can grab it, and "Straßenreinigung" /
/// "Gebäudereinigung" before a bare "Reinigung". Each line is matched to at
/// most one category (the first that hits), so ordering resolves the overlaps.
const List<(String, List<String>)> _categoryAliases = [
  ('warmwasser', ['warmwasser', 'warmwasserversorgung', 'wassererwärmung']),
  ('strassenreinigung', ['straßenreinigung', 'strassenreinigung', 'straßenrein']),
  ('reinigung', [
    'gebäudereinigung',
    'gebaeudereinigung',
    'hausreinigung',
    'treppenreinigung',
    'gebäuderein',
    'ungeziefer',
    'schädlingsbekämpfung',
    'schaedlingsbekaempfung',
  ]),
  ('wasser', [
    'wasserversorgung',
    'frischwasser',
    'kaltwasser',
    'abwasser',
    'entwässerung',
    'entwaesserung',
    'wasser/abwasser',
    'wasser',
  ]),
  ('heizung', [
    'heizungsbetrieb',
    'heizkosten',
    'heizung',
    'wärmelieferung',
    'waermelieferung',
    'brennstoff',
    'fernwärme',
    'fernwaerme',
  ]),
  ('grundsteuer', ['grundsteuer', 'grundabgabe']),
  ('aufzug', ['aufzugsanlage', 'aufzug', 'fahrstuhl']),
  ('muell', [
    'müllbeseitigung',
    'muellbeseitigung',
    'müllabfuhr',
    'muellabfuhr',
    'restmüll',
    'restmuell',
    'müll',
    'muell',
    'abfall',
  ]),
  ('garten', [
    'gartenpflege',
    'gartenarbeiten',
    'grünanlage',
    'gruenanlage',
    'grünpflege',
    'gruenpflege',
    'garten',
  ]),
  ('strom', [
    'allgemeinstrom',
    'allgemein-strom',
    'hausstrom',
    'beleuchtung',
    'strom',
  ]),
  ('schornstein', [
    'schornsteinreinigung',
    'schornsteinfeger',
    'kaminkehrer',
    'kaminreinigung',
    'schornstein',
  ]),
  ('versicherung', [
    'gebäudeversicherung',
    'gebaeudeversicherung',
    'haftpflichtversicherung',
    'sachversicherung',
    'sach- und haftpflicht',
    'sach-/haftpflicht',
    'versicherung',
  ]),
  ('hauswart', ['hauswart', 'hausmeister', 'hauswartkosten']),
  ('kabel', [
    'kabelanschluss',
    'kabelgebühr',
    'kabelgebuehr',
    'kabel-tv',
    'antennenanlage',
    'antenne',
    'breitband',
    'kabel',
  ]),
  ('waesche', ['wäschepflege', 'waeschepflege', 'waschküche', 'waschkueche', 'wäsche', 'waesche']),
  ('sonstige', ['sonstige betriebskosten', 'sonstige kosten', 'sonstiges', 'sonstige']),
];

/// Lines that are totals / balances, not individual positions — we never want
/// to read a category amount off these.
const List<String> _summaryMarkers = [
  'summe',
  'gesamt',
  'zwischensumme',
  'gesamtbetrag',
  'gesamtkosten',
  'saldo',
  'nachzahlung',
  'guthaben',
  'ergebnis',
];

class StatementParser {
  static ParsedStatement parse(String ocrText) {
    final rawLines = ocrText.split('\n');
    // Keep original + a normalized lowercase form per line.
    final lines = <String>[];
    final norm = <String>[];
    for (final l in rawLines) {
      final t = l.trim();
      if (t.isEmpty) continue;
      lines.add(t);
      norm.add(t.toLowerCase());
    }

    final amounts = <String, double>{};
    final consumed = List<bool>.filled(lines.length, false);

    // ---- category amounts ----
    for (final (id, aliases) in _categoryAliases) {
      for (var i = 0; i < lines.length; i++) {
        if (consumed[i]) continue;
        final line = norm[i];
        if (_isSummary(line)) continue;
        if (!aliases.any(line.contains)) continue;

        // Amount on the same line, else the next unconsumed line if it is
        // essentially just a number (label / value on separate rows).
        var amount = lastAmount(lines[i]);
        var hitIndex = i;
        if (amount == null && i + 1 < lines.length && !consumed[i + 1]) {
          final next = lines[i + 1];
          if (_isBareAmountLine(next)) {
            amount = lastAmount(next);
            hitIndex = i + 1;
          }
        }
        if (amount == null || amount <= 0) continue;

        amounts.putIfAbsent(id, () => amount!);
        consumed[i] = true;
        if (hitIndex != i) consumed[hitIndex] = true;
        break;
      }
    }

    // ---- apartment size ----
    double? size;
    for (var i = 0; i < norm.length; i++) {
      final l = norm[i];
      final hasLabel = l.contains('wohnfläche') ||
          l.contains('wohnflaeche') ||
          l.contains('wohnfl') ||
          l.contains('fläche der wohnung');
      final hasUnit = _sizeRegex.hasMatch(l);
      if (!hasLabel && !hasUnit) continue;

      double? v;
      final m = _sizeRegex.firstMatch(l);
      if (m != null) {
        // A number bound to a unit (m², m2, qm, or an OCR-mangled "m?").
        v = parseGermanAmount(m.group(1)!);
      } else if (hasLabel) {
        // OCR dropped the unit; take the last plausible number on the label
        // line (the size follows any apartment/house number).
        final nums = _plainNumber
            .allMatches(l)
            .map((x) => parseGermanAmount(x.group(0)!))
            .whereType<double>()
            .where((x) => x >= 5 && x <= 1000)
            .toList();
        if (nums.isNotEmpty) v = nums.last;
      }
      if (v != null && v >= 5 && v <= 1000) {
        size = v;
        break;
      }
    }

    // ---- prepayments ----
    double? prepaid;
    for (var i = 0; i < norm.length; i++) {
      final l = norm[i];
      if (l.contains('vorauszahlung') ||
          l.contains('vorauszahlungen') ||
          l.contains('geleistete zahlungen') ||
          l.contains('voraus­zahlung')) {
        final a = lastAmount(lines[i]);
        if (a != null && a > 0) {
          prepaid = a;
          break;
        }
      }
    }

    // ---- billing period ----
    DateTime? start;
    DateTime? end;
    final periodDates = _findPeriodDates(lines, norm);
    if (periodDates != null) {
      start = periodDates.$1;
      end = periodDates.$2;
    }

    return ParsedStatement(
      apartmentSize: size,
      prepaid: prepaid,
      periodStart: start,
      periodEnd: end,
      amounts: amounts,
    );
  }

  static bool _isSummary(String lowerLine) =>
      _summaryMarkers.any(lowerLine.contains);

  /// A line that is essentially just a euro amount (used for label-on-one-row,
  /// value-on-next-row layouts).
  static bool _isBareAmountLine(String line) {
    final stripped = line.replaceAll(RegExp(r'[€\seur.,0-9]', caseSensitive: false), '');
    return stripped.isEmpty && _amountRegex.hasMatch(line);
  }

  // --- German number handling ---------------------------------------------

  static final RegExp _amountRegex =
      RegExp(r'\d{1,3}(?:\.\d{3})+,\d{2}|\d+,\d{1,2}|\d+\.\d{2}(?!\d)|\d+');

  // Tolerates the common OCR corruption of "m²": the superscript 2 often
  // becomes "?", "2", or "³", so accept m followed by any of them.
  static final RegExp _sizeRegex = RegExp(
      r'(\d{1,4}(?:[.,]\d{1,2})?)\s*(?:m\s*[²2³?]|qm|quadratmeter)');

  static final RegExp _plainNumber = RegExp(r'\d{1,4}(?:[.,]\d{1,2})?');

  static final RegExp _dateRegex =
      RegExp(r'(\d{1,2})[.\-/](\d{1,2})[.\-/](\d{2,4})');

  /// The last euro-looking amount on a line (amounts sit at the right/end of a
  /// statement row). Returns null if none.
  static double? lastAmount(String line) {
    final matches = _amountRegex.allMatches(line).toList();
    if (matches.isEmpty) return null;
    // Walk from the end; the last plausible amount wins.
    for (final m in matches.reversed) {
      final v = parseGermanAmount(m.group(0)!);
      if (v != null) return v;
    }
    return null;
  }

  /// Parses a German-formatted number: "1.234,56" → 1234.56, "168,00" → 168,
  /// "62" → 62, "1.980" → 1980. Tolerates a trailing/leading € or spaces.
  static double? parseGermanAmount(String s) {
    var t = s.trim().replaceAll(RegExp(r'[€\s]'), '');
    if (t.isEmpty) return null;
    final hasComma = t.contains(',');
    final hasDot = t.contains('.');
    if (hasComma && hasDot) {
      // German: dot = thousands, comma = decimal.
      t = t.replaceAll('.', '').replaceAll(',', '.');
    } else if (hasComma) {
      // Comma is the decimal separator.
      t = t.replaceAll(',', '.');
    } else if (hasDot) {
      // Ambiguous: "1.980" (thousands) vs "1.98" (decimal). Treat a single dot
      // with exactly 3 trailing digits as a thousands separator.
      final parts = t.split('.');
      if (parts.length == 2 && parts[1].length == 3) {
        t = t.replaceAll('.', '');
      }
      // otherwise leave as-is (already a valid double string)
    }
    return double.tryParse(t);
  }

  static final RegExp _rangeRegex = RegExp(
    r'(\d{1,2}[.\-/]\d{1,2}[.\-/]\d{2,4})\s*(?:bis|–|—|‐|-|to)\s*(\d{1,2}[.\-/]\d{1,2}[.\-/]\d{2,4})',
    caseSensitive: false,
  );

  /// Finds the billing-period start/end. Strongest signal first: an explicit
  /// date range ("… bis …" / "… - …"), then a line naming the period, then a
  /// last-resort pair of dates.
  static (DateTime, DateTime)? _findPeriodDates(
      List<String> lines, List<String> norm) {
    // Pass 0: an explicit date range on a single line.
    for (final line in lines) {
      final m = _rangeRegex.firstMatch(line);
      if (m == null) continue;
      final d1 = _dateRegex.firstMatch(m.group(1)!);
      final d2 = _dateRegex.firstMatch(m.group(2)!);
      final a = d1 == null ? null : _toDate(d1);
      final b = d2 == null ? null : _toDate(d2);
      if (a != null && b != null && b.isAfter(a)) return (a, b);
    }

    // Pass 1: a line that names the period and carries two dates.
    for (var i = 0; i < lines.length; i++) {
      if (norm[i].contains('abrechnungszeitraum') ||
          norm[i].contains('zeitraum') ||
          norm[i].contains('abrechnung für') ||
          norm[i].contains('leistungszeitraum')) {
        final ds = _datesInWindow(lines, i);
        if (ds.length >= 2) return (ds[0], ds[1]);
      }
    }
    // Pass 2: first two dates anywhere.
    final all = <DateTime>[];
    for (final l in lines) {
      for (final m in _dateRegex.allMatches(l)) {
        final d = _toDate(m);
        if (d != null) all.add(d);
      }
    }
    if (all.length >= 2) {
      final a = all[0];
      final b = all.firstWhere((d) => d.isAfter(a), orElse: () => all[1]);
      if (b.isAfter(a)) return (a, b);
    }
    return null;
  }

  static List<DateTime> _datesInWindow(List<String> lines, int i) {
    final out = <DateTime>[];
    for (var j = i; j < lines.length && j <= i + 1; j++) {
      for (final m in _dateRegex.allMatches(lines[j])) {
        final d = _toDate(m);
        if (d != null) out.add(d);
      }
    }
    return out;
  }

  static DateTime? _toDate(RegExpMatch m) {
    final day = int.tryParse(m.group(1)!);
    final month = int.tryParse(m.group(2)!);
    var year = int.tryParse(m.group(3)!);
    if (day == null || month == null || year == null) return null;
    if (year < 100) year += 2000;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    if (year < 2000 || year > 2100) return null;
    return DateTime(year, month, day);
  }
}
