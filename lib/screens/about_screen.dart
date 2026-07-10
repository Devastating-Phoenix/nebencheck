import 'package:flutter/material.dart';

import '../data/cities.dart';
import '../data/remote_config.dart';
import '../theme.dart';
import '../ui/common.dart';
import '../util/l10n.dart';
import '../util/save_file.dart';
import 'legal_screen.dart';

/// "Anlage" to the audit form: what NebenCheck does, why the city
/// matters, how the score works, and what the limits are.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr('About NebenCheck', 'Über NebenCheck'),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
          children: [
            SectionLabel(tr('What this is', 'Worum es geht')),
            _Body(tr(
              'NebenCheck audits a German Nebenkostenabrechnung line by line. Every cost position is compared with reference values from the operating-cost survey (≈ DMB Betriebskostenspiegel), and the statement is checked against the formal rules of tenancy law. The result is a score, a verdict per position, and a ready objection letter. It is a university prototype — not legal advice.',
              'NebenCheck prüft eine Nebenkostenabrechnung Zeile für Zeile. Jede Kostenposition wird mit Referenzwerten aus dem Betriebskostenspiegel (≈ DMB) verglichen, die Abrechnung zusätzlich gegen die formellen Regeln des Mietrechts. Das Ergebnis: ein Score, ein Urteil je Position und ein fertiges Widerspruchsschreiben. Ein Hochschul-Prototyp — keine Rechtsberatung.',
            )),
            const SizedBox(height: 18),
            SectionLabel(
                tr('Why you select a city', 'Warum Sie eine Stadt wählen')),
            _Body(tr(
              'German tenancy law is federal: the 12-month delivery deadline, your 12-month objection window (§ 556 BGB) and the catalogue of chargeable costs (BetrKV) are identical in every city. The costs themselves are not:',
              'Das Mietrecht ist Bundesrecht: die 12-monatige Abrechnungsfrist, Ihre 12-monatige Widerspruchsfrist (§ 556 BGB) und der Katalog umlagefähiger Kosten (BetrKV) gelten in jeder Stadt gleich. Die Kosten selbst aber nicht:',
            )),
            const SizedBox(height: 10),
            _Reason(
              n: '1',
              title: tr('Municipal charges are set locally',
                  'Kommunale Abgaben werden vor Ort festgesetzt'),
              text: tr(
                'Every municipality sets its own Grundsteuer multiplier (Hebesatz) — Berlin charges 810%, other cities far less. Water, sewage and waste collection are municipal fees too, and they differ by hundreds of euros a year.',
                'Jede Gemeinde bestimmt ihren eigenen Grundsteuer-Hebesatz — Berlin verlangt 810 %, andere Städte deutlich weniger. Auch Wasser, Abwasser und Müllabfuhr sind kommunale Gebühren und unterscheiden sich um hunderte Euro im Jahr.',
              ),
            ),
            _Reason(
              n: '2',
              title: tr('Service costs follow regional wages',
                  'Dienstleistungen folgen dem regionalen Lohnniveau'),
              text: tr(
                'Caretakers, cleaning, gardening and chimney sweeps cost more in München than in Leipzig, because wages and prices differ regionally.',
                'Hauswart, Reinigung, Gartenpflege und Schornsteinfeger kosten in München mehr als in Leipzig, weil Löhne und Preise regional unterschiedlich sind.',
              ),
            ),
            _Reason(
              n: '3',
              title: tr('A fair verdict needs a fair yardstick',
                  'Ein faires Urteil braucht einen fairen Maßstab'),
              text: tr(
                'The same 0,30 € per m² and month for waste collection can be perfectly normal in Hamburg and clearly excessive in Dresden. Judging both against one national average would flag honest statements in expensive cities and wave through inflated ones in cheap cities.',
                'Dieselben 0,30 € pro m² und Monat für Müllabfuhr können in Hamburg völlig normal und in Dresden deutlich überhöht sein. Ein einziger Bundesdurchschnitt würde ehrliche Abrechnungen in teuren Städten anschwärzen und überhöhte in günstigen durchwinken.',
              ),
            ),
            const SizedBox(height: 6),
            _Body(tr(
              'NebenCheck uses two separate factors per city, because the two dimensions often point in opposite directions. Munich, for example, has expensive rents but among the lowest municipal fees in the country (rank 19 of 100), while Berlin has moderate rents but the highest fees (rank 94). A single "expensive city" factor would get one of them backwards. So municipal charges (property tax, water, waste, street cleaning) are scaled by the local fee level, building services (caretaker, cleaning, garden, elevator) by the regional wage level, and national-market costs (heating, hot water, insurance) are not scaled at all. The legal checks never change — the law is the same everywhere in Germany.',
              'NebenCheck verwendet zwei getrennte Faktoren je Stadt, weil beide Dimensionen oft gegenläufig sind. München etwa hat teure Mieten, aber mit die niedrigsten kommunalen Gebühren des Landes (Rang 19 von 100), während Berlin moderate Mieten, aber die höchsten Gebühren hat (Rang 94). Ein einziger „teure Stadt"-Faktor würde eine der beiden falsch einordnen. Deshalb werden kommunale Abgaben (Grundsteuer, Wasser, Müll, Straßenreinigung) nach dem lokalen Gebührenniveau skaliert, Gebäudedienste (Hauswart, Reinigung, Garten, Aufzug) nach dem regionalen Lohnniveau, und bundesweit gehandelte Kosten (Heizung, Warmwasser, Versicherung) gar nicht. Die rechtlichen Prüfungen ändern sich nie — das Gesetz ist überall in Deutschland gleich.',
            )),
            const SizedBox(height: 18),
            SectionLabel(tr('City factors used', 'Verwendete Stadtfaktoren')),
            _Body(tr(
              'Services × / fees × — 1.00 is the national average.',
              'Dienste × / Gebühren × — 1,00 ist der Bundesdurchschnitt.',
            )),
            const SizedBox(height: 8),
            SurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                children: [
                  for (final c in kCities)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.isNational
                                      ? tr('Germany · national average',
                                          'Deutschland · Bundesdurchschnitt')
                                      : (c.name == c.state
                                          ? c.name
                                          : '${c.name} · ${c.state}'),
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                                Builder(builder: (context) {
                                  final note = tr(c.note, c.noteDe);
                                  if (note.isEmpty) return const SizedBox();
                                  return Text(
                                    note,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      height: 1.35,
                                      color: AppColors.inkSoft,
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Builder(builder: (_) {
                            final svc = RemoteConfig.instance.serviceFactor(c);
                            final fee = RemoteConfig.instance.feeFactor(c);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('×${svc.toStringAsFixed(2)}',
                                    style: AppText.mono(size: 13)),
                                if (!c.isNational || fee != svc)
                                  Text('×${fee.toStringAsFixed(2)}',
                                      style: AppText.mono(
                                          size: 13, color: AppColors.inkSoft)),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SectionLabel(
                tr('How the score works', 'So funktioniert der Score')),
            _Body(tr(
              'Every statement starts at 100 points. It loses 12 points for each red position (far above the reference value of your city), 5 for each yellow one (worth checking), 15 for each item that may not be charged to tenants at all, 30 if the statement arrived after the legal 12-month deadline, 10 if the billing period is longer than 12 months, and 10 if heating is billed without the required consumption split (§ 12 HeizKV — this also adds a 15% cut to the letter). The score signals how much of the statement is worth questioning — it is not a legal verdict.',
              'Jede Abrechnung startet mit 100 Punkten. Sie verliert 12 Punkte je roter Position (deutlich über dem Referenzwert Ihrer Stadt), 5 je gelber (prüfenswert), 15 je Position, die gar nicht umlagefähig ist, 30 bei Zugang nach der gesetzlichen 12-Monats-Frist, 10 bei einem Abrechnungszeitraum über 12 Monaten und 10 bei Heizkosten ohne den vorgeschriebenen Verbrauchsanteil (§ 12 HeizKV — das Schreiben macht dann zusätzlich eine 15-%-Kürzung geltend). Der Score zeigt, wie viel der Abrechnung hinterfragenswert ist — er ist kein Rechtsurteil.',
            )),
            const SizedBox(height: 18),
            SectionLabel(tr('Sources & limits', 'Quellen & Grenzen')),
            _Body(tr(
              "National reference values are the DMB Betriebskostenspiegel for accounting year 2024 (national average 2,67 €/m²/month). Service factors use the DMB state-level totals (e.g. Berlin 2,81, Bavaria 2,58, Saxony 2,21 €/m²). Fee factors use the Haus & Grund / IW Consult Nebenkostenranking of the 100 largest cities (property tax, water and waste fees; Munich 1.058 €, Berlin 1.619 € per year). Where no published state value exists, a service factor is interpolated (marked \"estimate\" in the table). All of these are guide values: your building's age, heating system and contracts legitimately move costs. A yellow or red mark is a reason to ask for receipts — not proof of an error. NebenCheck is a university prototype and does not replace advice from a Mieterverein or a lawyer.",
              'Die bundesweiten Referenzwerte stammen aus dem DMB-Betriebskostenspiegel für das Abrechnungsjahr 2024 (Bundesdurchschnitt 2,67 €/m²/Monat). Die Dienstefaktoren nutzen die DMB-Landeswerte (z. B. Berlin 2,81, Bayern 2,58, Sachsen 2,21 €/m²). Die Gebührenfaktoren nutzen das Nebenkostenranking von Haus & Grund / IW Consult der 100 größten Städte (Grundsteuer, Wasser- und Müllgebühren; München 1.058 €, Berlin 1.619 € pro Jahr). Fehlt ein veröffentlichter Landeswert, wird der Dienstefaktor interpoliert (in der Tabelle mit „Schätzung" markiert). All das sind Richtwerte: Alter des Gebäudes, Heizungsanlage und Verträge verschieben Kosten legitim. Gelb oder Rot ist ein Anlass, Belege anzufordern — kein Beweis für einen Fehler. NebenCheck ist ein Hochschul-Prototyp und ersetzt keine Beratung durch Mieterverein oder Anwalt.',
            )),
            const SizedBox(height: 18),
            SectionLabel(tr('How the data is updated',
                'Wie die Daten aktualisiert werden')),
            _Body(tr(
              'NebenCheck is open source. The reference values and city factors live in a public GitHub repository, versioned so every change is traceable. They are updated when a new survey is published — the DMB Betriebskostenspiegel comes out yearly (around December); the Haus & Grund fee ranking less regularly. Because the project is public, anyone who spots an outdated or incorrect value can open an issue or propose a fix; changes are reviewed before they ship. If a number here looks wrong to you, please contribute a correction.',
              'NebenCheck ist quelloffen. Die Referenzwerte und Stadtfaktoren liegen in einem öffentlichen GitHub-Repository, versioniert, sodass jede Änderung nachvollziehbar ist. Sie werden aktualisiert, sobald eine neue Erhebung erscheint — der DMB-Betriebskostenspiegel jährlich (etwa im Dezember), das Gebührenranking von Haus & Grund seltener. Da das Projekt öffentlich ist, kann jede Person einen veralteten oder falschen Wert melden oder eine Korrektur vorschlagen; Änderungen werden vor der Veröffentlichung geprüft. Wenn Ihnen ein Wert hier falsch erscheint, tragen Sie bitte eine Korrektur bei.',
            )),
            const SizedBox(height: 12),
            _RepoLink(),
            const SizedBox(height: 4),
            InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LegalScreen()),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.balance_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      tr('Legal notice & privacy →', 'Impressum & Datenschutz →'),
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tappable "View / contribute on GitHub" row. The URL is filled in once
/// the public repository exists; until then it points to the org handle.
class _RepoLink extends StatelessWidget {
  static const _url = 'https://github.com/Devastating-Phoenix/nebencheck';

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => openExternal(_url),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.open_in_new_rounded,
                size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                tr('View source & suggest a correction on GitHub →',
                    'Quellcode ansehen & Korrektur vorschlagen auf GitHub →'),
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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

class _Reason extends StatelessWidget {
  final String n;
  final String title;
  final String text;

  const _Reason({required this.n, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 26, child: Text('$n.', style: AppText.mono(size: 15))),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
