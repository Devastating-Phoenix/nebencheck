import '../models/models.dart';
import '../util/format.dart';

/// Builds a formal German objection letter ("Widerspruch") from the report.
///
/// The letter is intentionally written in German: it is addressed to a
/// German landlord or property manager. The app explains it in English.
class LetterGenerator {
  static String build(StatementData data, AnalysisReport report) {
    final flagged =
        report.positions.where((p) => p.verdict != Verdict.ok).toList();
    final tenant = data.tenantName.isEmpty ? '[Ihr Name]' : data.tenantName;
    final landlord = data.landlordName.isEmpty
        ? '[Vermieter / Hausverwaltung]'
        : data.landlordName;
    final today = DateTime.now();
    final replyBy = today.add(const Duration(days: 28));

    final b = StringBuffer();
    b.writeln(tenant);
    b.writeln('[Ihre Anschrift]');
    b.writeln();
    b.writeln('An');
    b.writeln(landlord);
    b.writeln('[Anschrift]');
    b.writeln();
    b.writeln('[Ort], den ${fmtDate(today)}');
    b.writeln();
    b.writeln(
        'Widerspruch gegen die Betriebskostenabrechnung – Abrechnungszeitraum ${fmtDate(data.periodStart)} bis ${fmtDate(data.periodEnd)}');
    b.writeln();
    b.writeln('Sehr geehrte Damen und Herren,');
    b.writeln();
    b.writeln(
        'die o. g. Betriebskostenabrechnung ist mir am ${fmtDate(data.receivedDate)} zugegangen. Hiermit lege ich fristgerecht Widerspruch gegen die Abrechnung ein (§ 556 Abs. 3 Satz 5 BGB).');
    b.writeln();

    if (report.lateDelivery) {
      b.writeln(
          'Die Abrechnung ist mir erst nach Ablauf der gesetzlichen Abrechnungsfrist zugegangen (Fristende: ${fmtDate(report.deliveryDeadline)}). Nachforderungen sind damit gemäß § 556 Abs. 3 Satz 3 BGB ausgeschlossen.');
      b.writeln();
    }

    if (report.heatingCut > 0) {
      b.writeln(
          'Die Heizkosten wurden ohne die nach der Heizkostenverordnung vorgeschriebene verbrauchsabhängige Erfassung abgerechnet. Ich mache daher von meinem Kürzungsrecht nach § 12 Abs. 1 HeizKV Gebrauch und kürze den auf mich entfallenden Heizkostenanteil um 15 % (${fmtEuro(report.heatingCut)}).');
      b.writeln();
    }

    if (flagged.isNotEmpty) {
      b.writeln('Im Einzelnen bestehen Einwände gegen folgende Positionen:');
      b.writeln();
      for (final p in flagged) {
        b.writeln('- ${p.name}: ${fmtEuro(p.amount)} – ${p.letterReason}.');
      }
      b.writeln();
      b.writeln('Ich bitte Sie daher,');
      b.writeln(
          '1. mir Einsicht in die zugrunde liegenden Belege und Verträge zu gewähren (§ 259 BGB),');
      b.writeln(
          '2. die beanstandeten Positionen zu erläutern bzw. eine korrigierte Abrechnung zu erstellen.');
    } else {
      b.writeln(
          'Zur Prüfung der Abrechnung bitte ich Sie, mir Einsicht in die zugrunde liegenden Belege und Verträge zu gewähren (§ 259 BGB).');
    }
    b.writeln();
    b.writeln(
        'Eine etwaige Nachzahlung leiste ich bis zur abschließenden Klärung nur unter dem Vorbehalt der Rückforderung. Ich bitte um Ihre Rückmeldung bis zum ${fmtDate(replyBy)}.');
    b.writeln();
    b.writeln('Mit freundlichen Grüßen');
    b.writeln();
    b.writeln(tenant);
    return b.toString();
  }
}
