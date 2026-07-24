import 'package:flutter_test/flutter_test.dart';
import 'package:nebencheck/logic/calendar.dart';
import 'package:nebencheck/util/l10n.dart';

void main() {
  String ics({DateTime? deadline}) => buildDeadlineIcs(
        deadline: deadline ?? DateTime(2025, 12, 31),
        periodStart: DateTime(2024, 1, 1),
        periodEnd: DateTime(2024, 12, 31),
      );

  tearDown(() => AppLang.code = 'en');

  test('is a complete VCALENDAR with CRLF line endings', () {
    final s = ics();
    expect(s, startsWith('BEGIN:VCALENDAR\r\n'));
    expect(s, endsWith('END:VCALENDAR\r\n'));
    expect(s, contains('BEGIN:VEVENT\r\n'));
    // Every line break must be CRLF (RFC 5545) — no bare \n anywhere.
    expect(s.replaceAll('\r\n', '').contains('\n'), isFalse);
  });

  test('all-day event: DTSTART on the deadline, DTEND the day after', () {
    final s = ics();
    expect(s, contains('DTSTART;VALUE=DATE:20251231'));
    // Day after 31 Dec rolls the year over.
    expect(s, contains('DTEND;VALUE=DATE:20260101'));
  });

  test('reminder fires one month before the deadline', () {
    expect(ics(), contains('TRIGGER:-P30D'));
    expect(ics(), contains('ACTION:DISPLAY'));
  });

  test('UID is derived from the deadline so re-exports overwrite cleanly', () {
    final deadline = DateTime(2025, 6, 15);
    expect(ics(deadline: deadline),
        contains('UID:nc-${deadline.millisecondsSinceEpoch}@nebencheck'));
  });

  test('summary follows the UI language, English by default', () {
    expect(ics(), contains('SUMMARY:Objection deadline'));
    AppLang.code = 'de';
    expect(ics(), contains('SUMMARY:Widerspruchsfrist'));
  });

  test('description cites § 556 Abs. 3 BGB and the billing period', () {
    final s = ics();
    expect(s, contains('§ 556 Abs. 3 BGB'));
    expect(s, contains('01.01.2024'));
    expect(s, contains('31.12.2024'));
  });
}
