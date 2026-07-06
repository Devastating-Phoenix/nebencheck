import '../util/format.dart';
import '../util/l10n.dart';

/// Builds an iCalendar (.ics) file with the objection deadline as an
/// all-day event plus a reminder one month before. The file lives in
/// the user's own calendar — no accounts, no notifications from us.
String buildDeadlineIcs({
  required DateTime deadline,
  required DateTime periodStart,
  required DateTime periodEnd,
}) {
  String d(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}'
      '${t.month.toString().padLeft(2, '0')}'
      '${t.day.toString().padLeft(2, '0')}';
  final now = DateTime.now().toUtc();
  final stamp = '${d(now)}T'
      '${now.hour.toString().padLeft(2, '0')}'
      '${now.minute.toString().padLeft(2, '0')}'
      '${now.second.toString().padLeft(2, '0')}Z';
  final dayAfter = deadline.add(const Duration(days: 1));

  String esc(String s) => s
      .replaceAll('\\', '\\\\')
      .replaceAll(';', '\\;')
      .replaceAll(',', '\\,')
      .replaceAll('\n', '\\n');

  final summary = esc(tr(
    'Objection deadline — Nebenkostenabrechnung',
    'Widerspruchsfrist — Nebenkostenabrechnung',
  ));
  final description = esc(tr(
    'Last day to object to the Nebenkostenabrechnung for ${fmtDate(periodStart)}–${fmtDate(periodEnd)} (§ 556 Abs. 3 BGB). Created with NebenCheck.',
    'Letzter Tag für den Widerspruch gegen die Nebenkostenabrechnung ${fmtDate(periodStart)}–${fmtDate(periodEnd)} (§ 556 Abs. 3 BGB). Erstellt mit NebenCheck.',
  ));
  final alarm = esc(tr(
    'Objection window ends in one month',
    'Widerspruchsfrist endet in einem Monat',
  ));

  return [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//NebenCheck//Prototype//DE',
    'BEGIN:VEVENT',
    'UID:nc-${deadline.millisecondsSinceEpoch}@nebencheck',
    'DTSTAMP:$stamp',
    'DTSTART;VALUE=DATE:${d(deadline)}',
    'DTEND;VALUE=DATE:${d(dayAfter)}',
    'SUMMARY:$summary',
    'DESCRIPTION:$description',
    'BEGIN:VALARM',
    'TRIGGER:-P30D',
    'ACTION:DISPLAY',
    'DESCRIPTION:$alarm',
    'END:VALARM',
    'END:VEVENT',
    'END:VCALENDAR',
    '',
  ].join('\r\n');
}
