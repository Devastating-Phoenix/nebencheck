/// Pure-Dart formatting helpers (no Flutter imports) so that the analyzer
/// and the letter generator can be unit-tested without a widget environment.
library;

/// Formats a number in the German convention: `1.234,56 €`.
String fmtEuro(double value, {int decimals = 2}) {
  final negative = value < 0;
  final fixed = value.abs().toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final intPart = _group(parts[0]);
  final decPart = parts.length > 1 ? ',${parts[1]}' : '';
  return '${negative ? '-' : ''}$intPart$decPart €';
}

String _group(String digits) {
  final out = <String>[];
  var i = digits.length;
  while (i > 3) {
    out.insert(0, digits.substring(i - 3, i));
    i -= 3;
  }
  out.insert(0, digits.substring(0, i));
  return out.join('.');
}

/// `dd.MM.yyyy` (German convention).
String fmtDate(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd.$mm.${d.year}';
}

/// Parses German ("1.234,56") and English ("1234.56") style input.
double parseAmount(String raw) {
  var s = raw.trim().replaceAll('€', '').replaceAll(' ', '');
  if (s.isEmpty) return 0;
  if (s.contains(',')) {
    s = s.replaceAll('.', '').replaceAll(',', '.');
  }
  return double.tryParse(s) ?? 0;
}

/// Calendar-safe month addition (31 Jan + 1 month -> 28/29 Feb).
DateTime addMonths(DateTime d, int months) {
  final zeroBased = d.month - 1 + months;
  final year = d.year + zeroBased ~/ 12;
  final month = zeroBased % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, d.day > lastDay ? lastDay : d.day);
}
