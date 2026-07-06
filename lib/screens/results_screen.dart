import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/cities.dart';
import '../data/remote_config.dart';
import '../logic/analyzer.dart';
import '../logic/calendar.dart';
import '../logic/storage.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../ui/common.dart';
import '../util/format.dart';
import '../util/l10n.dart';
import '../util/save_file.dart';
import 'letter_screen.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  /// The most recent saved check whose billing period ended before this
  /// one started — i.e. last year's statement for the same flat.
  CheckSummary? _previousCheck(List<CheckSummary> history, StatementData d) {
    CheckSummary? best;
    DateTime? bestEnd;
    for (final h in history) {
      try {
        final end = DateTime.parse(h.statement['end'] as String);
        if (end.isBefore(d.periodStart) &&
            (bestEnd == null || end.isAfter(bestEnd))) {
          best = h;
          bestEnd = end;
        }
      } catch (_) {
        // Ignore malformed entries.
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final report = app.report;
    if (report == null) {
      return Scaffold(
          body: Center(
              child:
                  Text(tr('No analysis yet.', 'Noch keine Analyse.'))));
    }
    final draft = app.draft;
    final city = cityById(draft.cityId);
    final scoreColor = report.score >= 85
        ? AppColors.ok
        : (report.score >= 60 ? AppColors.elevated : AppColors.high);
    final scoreLabel = report.score >= 85
        ? tr('No objection', 'Kein Einwand')
        : (report.score >= 60
            ? tr('Worth\nchecking', 'Prüfung\nlohnt sich')
            : tr('Objection\nlikely', 'Widerspruch\nnaheliegend'));

    // Year-over-year comparison against the user's own previous check.
    Map<String, double>? prevPerSqm;
    String? prevYear;
    double? prevTotalPerSqm;
    final prev = _previousCheck(app.history, draft);
    if (prev != null) {
      try {
        final prevData = Storage.statementFromJson(prev.statement);
        final prevReport = Analyzer.analyze(prevData);
        prevPerSqm = {
          for (final p in prevReport.positions) p.name: p.perSqmMonth,
        };
        prevYear = prevData.periodEnd.year.toString();
        prevTotalPerSqm = prevReport.totalPerSqmMonth;
      } catch (_) {
        // A malformed saved check must never break the results screen.
      }
    }

    final deadlineOpen = report.objectionDeadline.isAfter(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr('Audit result', 'Prüfergebnis'),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
          children: [
            // The examiner's result box: typed score, stamp pressed
            // over the corner the way a real stamp overlaps the form.
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: AppColors.lineStrong),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PRÜFERGEBNIS', style: AppText.label()),
                      const SizedBox(height: 4),
                      Text(
                        '${report.score}/100',
                        style: AppText.mono(size: 34),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.potentialSavings > 0
                            ? tr(
                                'Up to ${fmtEuro(report.potentialSavings, decimals: 0)} of this statement is questionable',
                                'Bis zu ${fmtEuro(report.potentialSavings, decimals: 0)} dieser Abrechnung sind strittig',
                              )
                            : tr('No questionable amounts found',
                                'Keine strittigen Beträge gefunden'),
                        style: const TextStyle(
                          color: AppColors.inkSoft,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 8,
                  child: Stamp(scoreLabel, color: scoreColor, size: 13),
                ),
              ],
            ),
            const _ScoreInfo(),
            const SizedBox(height: 8),
            SurfaceCard(
              child: Column(
                children: [
                  _kv(tr('Total billed', 'Gesamt abgerechnet'),
                      fmtEuro(report.totalCosts)),
                  _kv(tr('Your prepayments', 'Ihre Vorauszahlungen'),
                      fmtEuro(draft.prepaid)),
                  const Divider(height: 18, color: AppColors.line),
                  _kv(
                    report.balance >= 0
                        ? tr('Back payment demanded', 'Geforderte Nachzahlung')
                        : tr('Credit in your favour',
                            'Guthaben zu Ihren Gunsten'),
                    fmtEuro(report.balance.abs()),
                    color:
                        report.balance >= 0 ? AppColors.high : AppColors.ok,
                  ),
                  const SizedBox(height: 8),
                  _kv(tr('Your costs per m²/month', 'Ihre Kosten pro m²/Monat'),
                      fmtEuro(report.totalPerSqmMonth)),
                  _kv(
                    city.isNational
                        ? tr('National reference, same positions',
                            'Bundesweiter Referenzwert, gleiche Positionen')
                        : tr('Reference (${city.name}), same positions',
                            'Referenzwert (${city.name}), gleiche Positionen'),
                    fmtEuro(report.benchmarkPerSqmMonth),
                  ),
                  _kv(
                    tr('Reference region', 'Referenzregion'),
                    city.isNational
                        ? tr('Germany Ø', 'Bundesweit Ø')
                        : city.name,
                  ),
                  if (!city.isNational)
                    Builder(builder: (_) {
                      final svc = RemoteConfig.instance
                          .serviceFactor(city)
                          .toStringAsFixed(2);
                      final fee =
                          RemoteConfig.instance.feeFactor(city).toStringAsFixed(2);
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                tr(
                                  'Local adjustment · services ×$svc · fees ×$fee',
                                  'Regionale Anpassung · Dienste ×$svc · Gebühren ×$fee',
                                ),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.inkSoft,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  if (prevTotalPerSqm != null && prevTotalPerSqm > 0)
                    _kv(
                      tr('vs your $prevYear check',
                          'ggü. Ihrer Prüfung $prevYear'),
                      _pctLabel(report.totalPerSqmMonth / prevTotalPerSqm),
                      color: _pctColor(
                          report.totalPerSqmMonth / prevTotalPerSqm),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SectionLabel(tr('Formal & legal checks',
                'Formelle & rechtliche Prüfungen')),
            SurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Column(
                children: [for (final c in report.checks) _checkTile(c)],
              ),
            ),
            if (deadlineOpen) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  final ics = buildDeadlineIcs(
                    deadline: report.objectionDeadline,
                    periodStart: draft.periodStart,
                    periodEnd: draft.periodEnd,
                  );
                  downloadBytes(
                    Uint8List.fromList(utf8.encode(ics)),
                    'nebencheck-widerspruchsfrist.ics',
                    'text/calendar',
                  );
                },
                icon: const Icon(Icons.event_outlined, size: 19),
                label: Text(tr('Add objection deadline to my calendar',
                    'Widerspruchsfrist in meinen Kalender')),
              ),
              const SizedBox(height: 4),
              Text(
                tr(
                  'Downloads a calendar file with a reminder one month before the window closes.',
                  'Lädt eine Kalenderdatei mit Erinnerung einen Monat vor Fristende herunter.',
                ),
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.inkSoft,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 18),
            SectionLabel(tr('Position by position', 'Position für Position')),
            const _TrafficLegend(),
            const SizedBox(height: 10),
            for (final (i, p) in report.positions.indexed)
              _positionCard(i + 1, p,
                  prev: prevPerSqm?[p.name], prevYear: prevYear),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LetterScreen()),
              ),
              child: Text(report.hasFindings || report.heatingCut > 0
                  ? tr('Draft my objection letter',
                      'Widerspruchsschreiben erstellen')
                  : tr('Draft a receipt inspection letter',
                      'Schreiben zur Belegeinsicht erstellen')),
            ),
            const SizedBox(height: 10),
            Text(
              city.isNational
                  ? tr(
                      'The ink tick on each bar marks the national reference value (≈ DMB Betriebskostenspiegel). These are guide values — actual costs vary by region, building and contract, so treat yellow and red as reasons to check, not as proof of an error. Not legal advice.',
                      'Die Tintenmarke auf jedem Balken zeigt den bundesweiten Referenzwert (≈ DMB-Betriebskostenspiegel). Das sind Richtwerte — tatsächliche Kosten variieren je nach Region, Gebäude und Vertrag. Gelb und Rot sind Anlässe zum Prüfen, kein Beweis für Fehler. Keine Rechtsberatung.',
                    )
                  : tr(
                      'The ink tick on each bar marks the reference value adjusted to ${city.name}: municipal charges (property tax, water, waste) by the local fee level and building services (caretaker, cleaning, garden) by regional wages, while heating and insurance stay national. Sources: DMB Betriebskostenspiegel 2024 and the Haus & Grund / IW fee ranking. These are guide values — building and contract still matter, so treat yellow and red as reasons to check, not proof of an error. Not legal advice.',
                      'Die Tintenmarke auf jedem Balken zeigt den auf ${city.name} angepassten Referenzwert: kommunale Abgaben (Grundsteuer, Wasser, Müll) nach dem lokalen Gebührenniveau, Gebäudedienste (Hauswart, Reinigung, Garten) nach den regionalen Löhnen, während Heizung und Versicherung bundesweit bleiben. Quellen: DMB-Betriebskostenspiegel 2024 und das Nebenkostenranking von Haus & Grund / IW. Das sind Richtwerte — Gebäude und Vertrag spielen weiter eine Rolle. Gelb und Rot sind Anlässe zum Prüfen, kein Beweis für Fehler. Keine Rechtsberatung.',
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

  static String _pctLabel(double ratio) {
    final pct = ((ratio - 1) * 100).round();
    return '${pct >= 0 ? '+' : ''}$pct %';
  }

  static Color _pctColor(double ratio) {
    final pct = (ratio - 1) * 100;
    if (pct >= 20) return AppColors.high;
    if (pct <= -5) return AppColors.ok;
    return AppColors.ink;
  }

  Widget _kv(String k, String v, {Color color = AppColors.ink}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(v, style: AppText.mono(size: 14.5, color: color)),
        ],
      ),
    );
  }

  Widget _checkTile(FormalCheck c) {
    final (icon, color) = switch (c.status) {
      CheckStatus.passed => (Icons.check_circle_rounded, AppColors.ok),
      CheckStatus.failed => (Icons.cancel_rounded, AppColors.high),
      CheckStatus.info => (Icons.info_rounded, AppColors.primary),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  c.detail,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.inkSoft,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _positionCard(int line, PositionResult p,
      {double? prev, String? prevYear}) {
    final color = verdictColor(p.verdict);
    final hasPrev = prev != null && prev > 0 && p.perSqmMonth > 0;
    final prevRatio = hasPrev ? p.perSqmMonth / prev : 1.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SurfaceCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  line.toString().padLeft(2, '0'),
                  style: AppText.mono(size: 13, color: AppColors.inkSoft),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    p.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                VerdictChip(p.verdict),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  fmtEuro(p.amount),
                  style: AppText.mono(size: 15, weight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  p.benchmark > 0
                      ? tr(
                          '${fmtEuro(p.perSqmMonth)} vs ${fmtEuro(p.benchmark)} /m²·mo',
                          '${fmtEuro(p.perSqmMonth)} vs. ${fmtEuro(p.benchmark)} /m²·Mon.',
                        )
                      : tr('not chargeable at all', 'gar nicht umlagefähig'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            BenchmarkBar(ratio: p.ratio, color: color),
            const SizedBox(height: 8),
            Text(
              p.note,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: p.verdict == Verdict.ok ? AppColors.inkSoft : color,
                fontWeight:
                    p.verdict == Verdict.ok ? FontWeight.w500 : FontWeight.w600,
              ),
            ),
            if (hasPrev) ...[
              const SizedBox(height: 4),
              Text(
                tr(
                  '${_pctLabel(prevRatio)} vs your $prevYear statement',
                  '${_pctLabel(prevRatio)} ggü. Ihrer Abrechnung $prevYear',
                ),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _pctColor(prevRatio) == AppColors.ink
                      ? AppColors.inkSoft
                      : _pctColor(prevRatio),
                ),
              ),
            ],
            if (p.excess > 0) ...[
              const SizedBox(height: 4),
              Text(
                tr('Questionable amount: ${fmtEuro(p.excess, decimals: 0)}',
                    'Strittiger Betrag: ${fmtEuro(p.excess, decimals: 0)}'),
                style: AppText.mono(size: 12.5, color: color),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Collapsible footnote explaining exactly how the score is computed.
class _ScoreInfo extends StatefulWidget {
  const _ScoreInfo();

  @override
  State<_ScoreInfo> createState() => _ScoreInfoState();
}

class _ScoreInfoState extends State<_ScoreInfo> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _open ? Icons.remove : Icons.add,
                  size: 15,
                  color: AppColors.inkSoft,
                ),
                const SizedBox(width: 6),
                Text(
                  tr('How is the score calculated?',
                      'Wie wird der Score berechnet?'),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.only(left: 21, bottom: 4),
            child: Text(
              tr(
                'Reference values are first scaled to the cost level of the city you selected. Every statement then starts at 100 points and loses 12 points for each red position (far above the reference value), 5 for each yellow one (worth checking), 15 for each item that may not be charged to tenants at all, 30 if the statement arrived after the legal 12-month deadline, 10 if the billing period is longer than 12 months, and 10 if heating is billed without the required consumption split. The score signals how much of the statement is worth questioning — it is not a legal verdict.',
                'Die Referenzwerte werden zunächst auf das Kostenniveau Ihrer Stadt skaliert. Jede Abrechnung startet dann mit 100 Punkten und verliert 12 Punkte je roter Position (deutlich über dem Referenzwert), 5 je gelber (prüfenswert), 15 je Position, die gar nicht umlagefähig ist, 30 bei Zugang nach der gesetzlichen 12-Monats-Frist, 10 bei einem Abrechnungszeitraum über 12 Monaten und 10 bei Heizkosten ohne den vorgeschriebenen Verbrauchsanteil. Der Score zeigt, wie viel der Abrechnung hinterfragenswert ist — er ist kein Rechtsurteil.',
              ),
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.55,
                color: AppColors.inkSoft,
              ),
            ),
          ),
      ],
    );
  }
}

/// Traffic-light legend for the position verdicts.
class _TrafficLegend extends StatelessWidget {
  const _TrafficLegend();

  @override
  Widget build(BuildContext context) {
    Widget entry(Color color, String title, String detail) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 9,
              height: 9,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$title — ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    TextSpan(
                      text: detail,
                      style: const TextStyle(color: AppColors.inkSoft),
                    ),
                  ],
                ),
                style: const TextStyle(fontSize: 12.5, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        entry(AppColors.ok, tr('Normal', 'Normal'),
            tr('within the usual range.', 'im üblichen Rahmen.')),
        entry(
            AppColors.elevated,
            tr('Worth checking', 'Prüfenswert'),
            tr('above the national reference value — ask for receipts.',
                'über dem Referenzwert — fragen Sie nach Belegen.')),
        entry(
            AppColors.high,
            tr('Objection likely', 'Deutlich überhöht'),
            tr('far above the reference value.',
                'weit über dem Referenzwert — Widerspruch naheliegend.')),
        entry(
            AppColors.legal,
            tr('Not chargeable §', 'Nicht umlagefähig §'),
            tr('may not be billed to tenants at all, regardless of amount.',
                'darf unabhängig von der Höhe gar nicht umgelegt werden.')),
      ],
    );
  }
}
