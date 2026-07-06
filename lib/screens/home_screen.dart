import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/cities.dart';
import '../logic/storage.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../ui/common.dart';
import '../util/format.dart';
import '../util/l10n.dart';
import 'about_screen.dart';
import 'results_screen.dart';
import 'statement_form_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<AppState>().history;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          children: [
            // Form head: name left, language + form number right.
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('NebenCheck',
                    style: AppText.display(size: 26)
                        .copyWith(color: AppColors.primary)),
                const Spacer(),
                const _LangToggle(),
                const SizedBox(width: 12),
                Text('PRÜFBOGEN · NK 26/1', style: AppText.label()),
              ],
            ),
            const SizedBox(height: 7),
            Container(height: 2, color: AppColors.primary),
            const SizedBox(height: 3),
            Container(height: 0.8, color: AppColors.primary),
            const SizedBox(height: 30),
            Text(
              tr('For German tenants · § 556 BGB · BetrKV',
                  'Für Mieter in Deutschland · § 556 BGB · BetrKV'),
              style: AppText.label(),
            ),
            const SizedBox(height: 10),
            // Headline with the auditor's red pencil under the finding.
            Text.rich(
              TextSpan(
                style: AppText.display(size: 44),
                children: [
                  TextSpan(
                      text: tr('Is your German utility bill ',
                          'Zahlen Sie bei Ihrer ')),
                  TextSpan(
                    text: tr('overcharging you?',
                        'Nebenkostenabrechnung drauf?'),
                    style: AppText.display(size: 44).copyWith(
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.high,
                      decorationThickness: 2.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              tr(
                'Tenant associations estimate that roughly every second Nebenkostenabrechnung contains at least one error. NebenCheck compares every line of yours with national benchmarks and the law — in about three minutes.',
                'Mietervereine schätzen, dass rund jede zweite Nebenkostenabrechnung mindestens einen Fehler enthält. NebenCheck vergleicht jede Position Ihrer Abrechnung mit Referenzwerten und dem Gesetz — in etwa drei Minuten.',
              ),
              style: const TextStyle(
                fontSize: 15.5,
                height: 1.55,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 22),
            // Summary strip: one ruled box, three printed fields.
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: AppColors.line),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _FormStat(
                        value: tr('~1 in 2', '~1 von 2'),
                        label: tr('statements contain errors',
                            'Abrechnungen mit Fehlern'),
                      ),
                    ),
                    Container(width: 1, color: AppColors.line),
                    Expanded(
                      child: _FormStat(
                        value: '2–3 €/m²',
                        label: tr('the "second rent", monthly',
                            'die „zweite Miete", monatlich'),
                      ),
                    ),
                    Container(width: 1, color: AppColors.line),
                    Expanded(
                      child: _FormStat(
                        value: tr('12 mo.', '12 Mon.'),
                        label: tr('window to object', 'Widerspruchsfrist'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 26),
            FilledButton(
              onPressed: () {
                context.read<AppState>().startNew();
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const StatementFormScreen()),
                );
              },
              child: Text(tr('Check my statement', 'Abrechnung prüfen')),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                context.read<AppState>().loadDemo();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ResultsScreen()),
                );
              },
              child: Text(tr('See a demo analysis', 'Demo-Analyse ansehen')),
            ),
            if (history.isNotEmpty) ...[
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: Text(
                        tr('RECENT CHECKS', 'LETZTE PRÜFUNGEN'),
                        style: AppText.label()),
                  ),
                  InkWell(
                    onTap: () => context.read<AppState>().clearHistory(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      child: Text(
                        tr('CLEAR', 'LÖSCHEN'),
                        style: AppText.label(color: AppColors.inkSoft)
                            .copyWith(fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  children: [
                    for (final (i, h) in history.indexed) ...[
                      if (i > 0) Container(height: 1, color: AppColors.line),
                      _HistoryRow(h),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tr('Saved in this browser only — nothing is uploaded.',
                    'Nur in diesem Browser gespeichert — nichts wird hochgeladen.'),
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.inkSoft,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 34),
            SectionLabel(
                tr('How the audit works', 'So funktioniert die Prüfung')),
            const SizedBox(height: 4),
            _Step(
              n: '1',
              title: tr('Copy the numbers', 'Zahlen übertragen'),
              text: tr(
                'Take your paper statement and enter apartment size, period and each cost line.',
                'Nehmen Sie Ihre Abrechnung und erfassen Sie Wohnfläche, Zeitraum und jede Kostenposition.',
              ),
            ),
            _Step(
              n: '2',
              title: tr('Get verdicts', 'Urteile erhalten'),
              text: tr(
                'Every position is compared with the national Betriebskostenspiegel and legal rules (§ 556 BGB, BetrKV, TKG).',
                'Jede Position wird mit dem Betriebskostenspiegel und den gesetzlichen Regeln verglichen (§ 556 BGB, BetrKV, TKG).',
              ),
            ),
            _Step(
              n: '3',
              title: tr('Object in one tap', 'Mit einem Klick widersprechen'),
              text: tr(
                'NebenCheck drafts a formal German objection letter with a receipt-inspection request.',
                'NebenCheck erstellt ein formelles Widerspruchsschreiben inklusive Antrag auf Belegeinsicht.',
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        tr('ABOUT NEBENCHECK — WHY YOUR CITY CHANGES THE SCORE',
                            'ÜBER NEBENCHECK — WARUM IHRE STADT DEN SCORE ÄNDERT'),
                        style: AppText.label().copyWith(fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(height: 0.8, color: AppColors.line),
            const SizedBox(height: 10),
            Text(
              tr(
                'University prototype. Reference values approximate the DMB Betriebskostenspiegel, adjusted to your selected city. This is not legal advice.',
                'Hochschul-Prototyp. Referenzwerte approximieren den DMB-Betriebskostenspiegel, angepasst an Ihre Stadt. Keine Rechtsberatung.',
              ),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.inkSoft,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// DE | EN segmented pill; the active language is printed in Amtsgrün.
class _LangToggle extends StatelessWidget {
  const _LangToggle();

  @override
  Widget build(BuildContext context) {
    Widget seg(String code) {
      final active = AppLang.code == code;
      return InkWell(
        onTap: () => context.read<AppState>().setLang(code),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            code.toUpperCase(),
            style: AppText.label(
                    color: active ? AppColors.primary : AppColors.inkSoft)
                .copyWith(
              fontSize: 11.5,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg('de'),
          Container(width: 1, height: 16, color: AppColors.line),
          seg('en'),
        ],
      ),
    );
  }
}

/// One saved check in the "Recent checks" box: typed date, city,
/// questionable amount and the score in its verdict color.
class _HistoryRow extends StatelessWidget {
  final CheckSummary entry;

  const _HistoryRow(this.entry);

  @override
  Widget build(BuildContext context) {
    final scoreColor = entry.score >= 85
        ? AppColors.ok
        : (entry.score >= 60 ? AppColors.elevated : AppColors.high);
    final city = cityById(entry.cityId);
    return InkWell(
      onTap: () {
        context.read<AppState>().openSaved(entry);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ResultsScreen()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            Text(fmtDate(entry.savedAt), style: AppText.mono(size: 12.5)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    city.isNational
                        ? tr('National Ø', 'Bundesweit Ø')
                        : city.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    entry.savings > 0
                        ? tr('${fmtEuro(entry.savings, decimals: 0)} questionable',
                            '${fmtEuro(entry.savings, decimals: 0)} strittig')
                        : tr('nothing questionable', 'nichts zu beanstanden'),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${entry.score}/100',
              style: AppText.mono(size: 13.5, color: scoreColor),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.inkSoft),
          ],
        ),
      ),
    );
  }
}

/// One printed field in the summary strip: typed value over a green label.
class _FormStat extends StatelessWidget {
  final String value;
  final String label;

  const _FormStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppText.mono(size: 15)),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: AppText.label().copyWith(fontSize: 10.5, letterSpacing: 1.1),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String n;
  final String title;
  final String text;

  const _Step({required this.n, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Typed line number, like "Zeile 31" on a tax form.
          SizedBox(
            width: 30,
            child: Text('$n.', style: AppText.mono(size: 16)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13.5,
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
