import 'package:flutter/material.dart';

import '../theme.dart';
import '../ui/common.dart';
import '../util/l10n.dart';

// Operator (§ 5 DDG). A foreign address is valid — it must simply be a real,
// reachable postal address.
const _operatorName = 'Mohsin Hadi';
const _operatorStreet = 'Lake City';
const _operatorCity = 'Lahore, Pakistan';
const _operatorEmail = 'mohsinhadi728@gmail.com';

/// Impressum (§ 5 DDG) and Datenschutzerklärung (Art. 13 DSGVO).
///
/// The privacy text documents what the app actually does: statements are
/// processed only in the browser, nothing is uploaded, names are never
/// persisted, and the only third parties are the hoster (Vercel) and the
/// reference-data fetch from GitHub.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr('Legal notice & privacy', 'Impressum & Datenschutz'),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
          children: [
            // ----------------------------------------------------- Impressum
            SectionLabel(tr('Legal notice (Impressum)', 'Impressum')),
            _Body(tr('Information pursuant to § 5 DDG:',
                'Angaben gemäß § 5 DDG:')),
            const SizedBox(height: 8),
            const _Contact(),
            const SizedBox(height: 10),
            _Body(tr(
              'Responsible for the content: $_operatorName (address above). '
              'NebenCheck is a non-commercial university prototype. It provides '
              'automated, general information about operating-cost statements '
              'and does not provide legal advice (no Rechtsdienstleistung '
              'within the meaning of the RDG). Results are non-binding guide '
              'values; for individual legal questions contact a Mieterverein '
              'or a lawyer.',
              'Verantwortlich für den Inhalt: $_operatorName (Anschrift wie '
              'oben). NebenCheck ist ein nicht-kommerzieller Hochschul-'
              'Prototyp. Die App liefert automatisierte, allgemeine '
              'Informationen zu Betriebskostenabrechnungen und erbringt keine '
              'Rechtsberatung (keine Rechtsdienstleistung i. S. d. RDG). '
              'Ergebnisse sind unverbindliche Richtwerte; für individuelle '
              'Rechtsfragen wenden Sie sich an einen Mieterverein oder eine '
              'Anwältin / einen Anwalt.',
            )),
            const SizedBox(height: 22),

            // ------------------------------------------------- Datenschutz
            SectionLabel(tr('Privacy policy', 'Datenschutzerklärung')),
            _Sub(tr('1. Controller', '1. Verantwortlicher')),
            _Body(tr(
              '$_operatorName, $_operatorStreet, $_operatorCity — '
              'email: $_operatorEmail.',
              '$_operatorName, $_operatorStreet, $_operatorCity — '
              'E-Mail: $_operatorEmail.',
            )),
            _Sub(tr('2. The core principle: your statement stays on your device',
                '2. Grundprinzip: Ihre Abrechnung bleibt auf Ihrem Gerät')),
            _Body(tr(
              'Everything you enter — amounts, dates, apartment size, names — '
              'is processed exclusively in your browser. Photos and documents '
              'you import are read on your device (local OCR / text '
              'extraction); the file is never uploaded and is discarded after '
              'reading. We operate no server that receives, stores or can '
              'even see your statement data. Tenant and landlord names are '
              'used only for the generated letter and are never saved.',
              'Alles, was Sie eingeben — Beträge, Daten, Wohnfläche, Namen — '
              'wird ausschließlich in Ihrem Browser verarbeitet. Importierte '
              'Fotos und Dokumente werden auf Ihrem Gerät ausgelesen (lokale '
              'OCR / Textextraktion); die Datei wird niemals hochgeladen und '
              'nach dem Auslesen verworfen. Wir betreiben keinen Server, der '
              'Ihre Abrechnungsdaten empfängt, speichert oder auch nur sehen '
              'kann. Mieter- und Vermieternamen werden nur für das erzeugte '
              'Schreiben verwendet und nie gespeichert.',
            )),
            _Sub(tr('3. Local storage on your device',
                '3. Lokale Speicherung auf Ihrem Gerät')),
            _Body(tr(
              'Saved checks (without names) and your language choice are kept '
              'in your browser’s local storage. This is technically '
              'necessary for the save function (§ 25 (2) TDDDG) — no consent '
              'banner is required because nothing is used for tracking. You '
              'can delete this data at any time by clearing the site data in '
              'your browser. There are no cookies, no analytics, no tracking '
              'and no advertising.',
              'Gespeicherte Prüfungen (ohne Namen) und Ihre Sprachwahl liegen '
              'im lokalen Speicher Ihres Browsers. Das ist für die '
              'Speicherfunktion technisch erforderlich (§ 25 Abs. 2 TDDDG) — '
              'ein Consent-Banner ist nicht nötig, da nichts zu Tracking-'
              'Zwecken verwendet wird. Sie können diese Daten jederzeit über '
              'die Website-Daten Ihres Browsers löschen. Es gibt keine '
              'Cookies, keine Analyse-Tools, kein Tracking und keine Werbung.',
            )),
            _Sub(tr('4. Hosting (Vercel)', '4. Hosting (Vercel)')),
            _Body(tr(
              'The app’s static files are delivered by Vercel Inc. (USA). '
              'When you open the site, Vercel technically processes your IP '
              'address and standard request metadata (server logs) — legal '
              'basis Art. 6 (1) (f) GDPR (secure, functional delivery); '
              'transfers rely on the EU-US Data Privacy Framework and '
              'standard contractual clauses. Your statement data is never '
              'part of these requests.',
              'Die statischen App-Dateien liefert Vercel Inc. (USA) aus. Beim '
              'Aufruf verarbeitet Vercel technisch bedingt Ihre IP-Adresse '
              'und übliche Anfrage-Metadaten (Server-Logs) — Rechtsgrundlage '
              'Art. 6 Abs. 1 lit. f DSGVO (sichere, funktionsfähige '
              'Auslieferung); Übermittlungen stützen sich auf das EU-US Data '
              'Privacy Framework und Standardvertragsklauseln. Ihre '
              'Abrechnungsdaten sind nie Teil dieser Anfragen.',
            )),
            _Sub(tr('5. Reference data (GitHub)', '5. Referenzdaten (GitHub)')),
            _Body(tr(
              'On startup the app fetches one public data file (reference '
              'values) from GitHub (GitHub Inc., USA); GitHub thereby sees '
              'your IP address. The request contains no personal data beyond '
              'that. Fonts and the OCR libraries are served from our own '
              'origin — no Google Fonts, no third-party CDN.',
              'Beim Start lädt die App eine öffentliche Datendatei '
              '(Referenzwerte) von GitHub (GitHub Inc., USA); GitHub sieht '
              'dabei Ihre IP-Adresse. Die Anfrage enthält darüber hinaus '
              'keine personenbezogenen Daten. Schriften und OCR-Bibliotheken '
              'werden von unserem eigenen Server geladen — keine Google '
              'Fonts, kein Dritt-CDN.',
            )),
            _Sub(tr('6. Your rights', '6. Ihre Rechte')),
            _Body(tr(
              'You have the rights under Art. 15–21 GDPR (access, '
              'rectification, erasure, restriction, portability, objection) '
              'and the right to complain to a supervisory authority. Note: '
              'because your statement data never reaches us, there is '
              'normally nothing we could disclose or erase — the data is '
              'only on your device.',
              'Ihnen stehen die Rechte aus Art. 15–21 DSGVO zu (Auskunft, '
              'Berichtigung, Löschung, Einschränkung, Übertragbarkeit, '
              'Widerspruch) sowie das Beschwerderecht bei einer '
              'Aufsichtsbehörde. Hinweis: Da Ihre Abrechnungsdaten uns nie '
              'erreichen, gibt es im Regelfall nichts, was wir beauskunften '
              'oder löschen könnten — die Daten liegen nur auf Ihrem Gerät.',
            )),
            const SizedBox(height: 10),
            _Body(tr('Version: July 2026.', 'Stand: Juli 2026.')),
          ],
        ),
      ),
    );
  }
}

/// The operator's contact block, typed like an entry on the form.
class _Contact extends StatelessWidget {
  const _Contact();

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_operatorName, style: AppText.mono(size: 14)),
          const SizedBox(height: 2),
          Text(_operatorStreet,
              style: AppText.mono(size: 14, weight: FontWeight.w400)),
          Text(_operatorCity,
              style: AppText.mono(size: 14, weight: FontWeight.w400)),
          const SizedBox(height: 6),
          Text('${tr('Email', 'E-Mail')}: $_operatorEmail',
              style: AppText.mono(size: 14, weight: FontWeight.w400)),
        ],
      ),
    );
  }
}

class _Sub extends StatelessWidget {
  final String text;

  const _Sub(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final String text;

  const _Body(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13.5,
        height: 1.55,
        color: AppColors.inkSoft,
      ),
    );
  }
}
