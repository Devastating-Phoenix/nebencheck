import '../data/benchmarks.dart';
import '../data/cities.dart';
import '../data/remote_config.dart';
import '../models/models.dart';
import '../util/format.dart';
import '../util/l10n.dart';

/// Turns a [StatementData] into an [AnalysisReport].
///
/// Two kinds of findings are produced:
///  1. Benchmark findings — a position costs significantly more per m² and
///     month than the national reference value.
///  2. Legal findings — formal rules from § 556 BGB, BetrKV and TKG that can
///     invalidate a charge regardless of its size.
class Analyzer {
  /// Above this ratio a position counts as "elevated".
  static const double elevatedThreshold = 1.25;

  /// Above this ratio a position counts as "far above average".
  static const double highThreshold = 1.6;

  static AnalysisReport analyze(StatementData data) {
    final days = data.periodEnd.difference(data.periodStart).inDays + 1;
    final months = days / 30.4375;
    final size = data.apartmentSize;
    final safeDivisor = (size > 0 && months > 0) ? size * months : 1.0;

    // Reference values are scaled to the selected city's cost level.
    // The formal/legal checks below are federal law and never scale.
    final city = cityById(data.cityId);

    final positions = <PositionResult>[];
    var totalCosts = 0.0;
    var benchmarkSum = 0.0;

    for (final entry in data.entries) {
      if (!entry.included || entry.amount <= 0) continue;
      totalCosts += entry.amount;
      benchmarkSum += RemoteConfig.instance.nat(
              entry.category.id, entry.category.benchmark) *
          RemoteConfig.instance.factorFor(city, entry.category.id);
      positions.add(_checkEntry(entry, safeDivisor, data.periodEnd, city));
    }

    for (final item in data.customItems) {
      if (item.amount <= 0) continue;
      totalCosts += item.amount;
      positions.add(_checkCustom(item, safeDivisor, city));
    }

    var savings = 0.0;
    for (final p in positions) {
      savings += p.excess;
    }

    // ---- heating 15% cut (§ 12 HeizKV) ----------------------------------
    // If heating is billed without the required consumption split, the
    // tenant may unilaterally cut the heating bill by 15%.
    var heatingAmount = 0.0;
    for (final e in data.entries) {
      if (e.included && e.category.id == 'heizung' && e.amount > 0) {
        heatingAmount += e.amount;
      }
    }
    final heatingCut =
        data.heatingBilling == 'flat' && heatingAmount > 0
            ? heatingAmount * 0.15
            : 0.0;
    savings += heatingCut;

    // ---- formal checks --------------------------------------------------
    final deliveryDeadline = addMonths(data.periodEnd, 12);
    final lateDelivery = data.receivedDate.isAfter(deliveryDeadline);
    final objectionDeadline = addMonths(data.receivedDate, 12);
    final daysLeft = objectionDeadline.difference(DateTime.now()).inDays;

    final heatingCheck = heatingCut > 0
        ? FormalCheck(
            title: tr('Heating billed by consumption',
                'Verbrauchsabhängige Heizkostenabrechnung'),
            detail: tr(
              'Your heating is billed without the required consumption split. § 12 HeizKV lets you cut the heating bill by 15% — that is ${fmtEuro(heatingCut)}. The objection letter claims this cut.',
              'Ihre Heizkosten werden ohne die vorgeschriebene verbrauchsabhängige Erfassung abgerechnet. § 12 HeizKV erlaubt eine Kürzung um 15 % — das sind ${fmtEuro(heatingCut)}. Das Widerspruchsschreiben macht diese Kürzung geltend.',
            ),
            status: CheckStatus.failed,
          )
        : data.heatingBilling == 'consumption'
            ? FormalCheck(
                title: tr('Heating billed by consumption',
                    'Verbrauchsabhängige Heizkostenabrechnung'),
                detail: tr(
                  'You confirmed that at least 50% is billed by actual consumption, as the Heizkostenverordnung requires.',
                  'Sie haben bestätigt, dass mindestens 50 % verbrauchsabhängig abgerechnet werden, wie es die Heizkostenverordnung verlangt.',
                ),
                status: CheckStatus.passed,
              )
            : FormalCheck(
                title: tr('Heating billed by consumption',
                    'Verbrauchsabhängige Heizkostenabrechnung'),
                detail: tr(
                  'At least 50% of heating and hot water must be billed by actual consumption (Heizkostenverordnung). Check the split on your statement — if it is missing, you may cut the heating bill by 15%.',
                  'Mindestens 50 % der Heiz- und Warmwasserkosten müssen verbrauchsabhängig abgerechnet werden (Heizkostenverordnung). Prüfen Sie den Verteilerschlüssel — fehlt er, dürfen Sie die Heizkosten um 15 % kürzen.',
                ),
                status: CheckStatus.info,
              );

    final checks = <FormalCheck>[
      FormalCheck(
        title: tr('Delivered within 12 months',
            'Zugang innerhalb von 12 Monaten'),
        detail: lateDelivery
            ? tr(
                'Deadline was ${fmtDate(deliveryDeadline)}, received ${fmtDate(data.receivedDate)}. A back payment is generally no longer enforceable (§ 556 Abs. 3 BGB).',
                'Frist war der ${fmtDate(deliveryDeadline)}, zugegangen am ${fmtDate(data.receivedDate)}. Eine Nachforderung ist damit in der Regel ausgeschlossen (§ 556 Abs. 3 BGB).',
              )
            : tr(
                'Received ${fmtDate(data.receivedDate)}, within the deadline of ${fmtDate(deliveryDeadline)} (§ 556 Abs. 3 BGB).',
                'Zugegangen am ${fmtDate(data.receivedDate)}, innerhalb der Frist bis ${fmtDate(deliveryDeadline)} (§ 556 Abs. 3 BGB).',
              ),
        status: lateDelivery ? CheckStatus.failed : CheckStatus.passed,
      ),
      FormalCheck(
        title: tr('Billing period max. 12 months',
            'Abrechnungszeitraum max. 12 Monate'),
        detail: days <= 366
            ? tr(
                'The period covers ${months.toStringAsFixed(1)} months — allowed.',
                'Der Zeitraum umfasst ${months.toStringAsFixed(1)} Monate — zulässig.',
              )
            : tr(
                'The period covers ${months.toStringAsFixed(1)} months. More than 12 months is not permitted.',
                'Der Zeitraum umfasst ${months.toStringAsFixed(1)} Monate. Mehr als 12 Monate sind nicht zulässig.',
              ),
        status: days <= 366 ? CheckStatus.passed : CheckStatus.failed,
      ),
      FormalCheck(
        title: tr('Your objection window', 'Ihre Widerspruchsfrist'),
        detail: daysLeft >= 0
            ? tr(
                'You can object until ${fmtDate(objectionDeadline)} ($daysLeft days left).',
                'Sie können bis zum ${fmtDate(objectionDeadline)} widersprechen (noch $daysLeft Tage).',
              )
            : tr(
                'The 12-month objection window ended on ${fmtDate(objectionDeadline)}.',
                'Die 12-monatige Widerspruchsfrist endete am ${fmtDate(objectionDeadline)}.',
              ),
        status: daysLeft >= 0 ? CheckStatus.passed : CheckStatus.failed,
      ),
      heatingCheck,
    ];

    // ---- score ----------------------------------------------------------
    var score = 100;
    for (final p in positions) {
      switch (p.verdict) {
        case Verdict.high:
          score -= 12;
        case Verdict.elevated:
          score -= 5;
        case Verdict.notApportionable:
          score -= 15;
        case Verdict.ok:
          break;
      }
    }
    if (lateDelivery) score -= 30;
    if (days > 366) score -= 10;
    if (heatingCut > 0) score -= 10;
    if (score < 5) score = 5;

    positions.sort((a, b) {
      final rank = _rank(a.verdict).compareTo(_rank(b.verdict));
      if (rank != 0) return rank;
      return b.excess.compareTo(a.excess);
    });

    return AnalysisReport(
      positions: positions,
      checks: checks,
      months: months,
      totalCosts: totalCosts,
      totalPerSqmMonth: totalCosts / safeDivisor,
      benchmarkPerSqmMonth: benchmarkSum,
      balance: totalCosts - data.prepaid,
      potentialSavings: savings,
      lateDelivery: lateDelivery,
      deliveryDeadline: deliveryDeadline,
      objectionDeadline: objectionDeadline,
      score: score,
      heatingCut: heatingCut,
    );
  }

  static int _rank(Verdict v) {
    switch (v) {
      case Verdict.notApportionable:
        return 0;
      case Verdict.high:
        return 1;
      case Verdict.elevated:
        return 2;
      case Verdict.ok:
        return 3;
    }
  }

  static PositionResult _checkEntry(
    CostEntry entry,
    double divisor,
    DateTime periodEnd,
    City city,
  ) {
    final c = entry.category;
    final reference = RemoteConfig.instance.nat(c.id, c.benchmark) *
        RemoteConfig.instance.factorFor(city, c.id);
    final perSqmMonth = entry.amount / divisor;
    final ratio = reference > 0 ? perSqmMonth / reference : 0.0;
    final benchmarkTotal = reference * divisor;

    // Special rule: cable TV is no longer apportionable for periods after
    // 30 June 2024 (end of the "Nebenkostenprivileg", TKG reform).
    if (c.id == 'kabel' && periodEnd.isAfter(kCableCutoff)) {
      return PositionResult(
        name: AppLang.isDe ? c.nameDe : '${c.nameDe} · ${c.nameEn}',
        amount: entry.amount,
        perSqmMonth: perSqmMonth,
        benchmark: 0,
        ratio: ratio,
        verdict: Verdict.notApportionable,
        excess: entry.amount,
        note: tr(
          'Cable TV can no longer be billed as an operating cost for periods after 30 June 2024.',
          'Kabel-TV darf für Zeiträume nach dem 30.06.2024 nicht mehr als Betriebskosten umgelegt werden.',
        ),
        letterReason:
            'ist seit dem 01.07.2024 nicht mehr als Betriebskosten umlagefähig (Ende des Nebenkostenprivilegs, TKG-Novelle); die Position ist zu streichen',
      );
    }

    Verdict verdict;
    var excess = 0.0;
    String note;
    var letterReason = '';
    final pct = ((ratio - 1) * 100).round();
    final refEn =
        city.isNational ? 'national reference value' : '${city.name} reference value';
    final refDeUi = city.isNational
        ? 'den bundesweiten Referenzwert'
        : 'den Referenzwert für ${city.name}';
    final refDe = city.isNational
        ? 'dem bundesweiten Referenzwert'
        : 'dem regionalen Referenzwert für ${city.name}';

    if (ratio >= highThreshold) {
      verdict = Verdict.high;
      excess = entry.amount - benchmarkTotal;
      note = tr(
        'About $pct% above the $refEn — likely worth objecting. Request receipt inspection.',
        'Rund $pct % über $refDeUi — Widerspruch naheliegend. Fordern Sie Belegeinsicht.',
      );
      letterReason =
          'liegt mit ${fmtEuro(perSqmMonth)} pro m² und Monat deutlich über $refDe von ${fmtEuro(reference)} (Betriebskostenspiegel, ca. +$pct %)';
    } else if (ratio >= elevatedThreshold) {
      verdict = Verdict.elevated;
      excess = entry.amount - benchmarkTotal;
      note = tr(
        'About $pct% above the $refEn — worth checking. Ask for the underlying receipts.',
        'Rund $pct % über $refDeUi — prüfenswert. Fragen Sie nach den Belegen.',
      );
      letterReason =
          'liegt mit ${fmtEuro(perSqmMonth)} pro m² und Monat über $refDe von ${fmtEuro(reference)} (ca. +$pct %)';
    } else {
      verdict = Verdict.ok;
      note = tr('Within the usual range.', 'Im üblichen Rahmen.');
    }

    return PositionResult(
      name: AppLang.isDe ? c.nameDe : '${c.nameDe} · ${c.nameEn}',
      amount: entry.amount,
      perSqmMonth: perSqmMonth,
      benchmark: reference,
      ratio: ratio,
      verdict: verdict,
      excess: excess < 0 ? 0 : excess,
      note: note,
      letterReason: letterReason,
    );
  }

  static PositionResult _checkCustom(
      CustomItem item, double divisor, City city) {
    final perSqmMonth = item.amount / divisor;
    final lower = item.name.toLowerCase();
    final matched = kNonApportionableKeywords.any((k) => lower.contains(k));
    final name = item.name.isEmpty ? 'Unnamed item' : item.name;

    if (matched) {
      return PositionResult(
        name: name,
        amount: item.amount,
        perSqmMonth: perSqmMonth,
        benchmark: 0,
        ratio: 0,
        verdict: Verdict.notApportionable,
        excess: item.amount,
        note: tr(
          'Administration, repairs, reserves and banking costs may not be passed on to tenants (§ 1 Abs. 2 BetrKV).',
          'Verwaltung, Reparaturen, Rücklagen und Bankkosten dürfen nicht auf Mieter umgelegt werden (§ 1 Abs. 2 BetrKV).',
        ),
        letterReason:
            'ist als Verwaltungs-/Instandhaltungsposition gemäß § 1 Abs. 2 BetrKV nicht auf Mieter umlagefähig; die Position ist zu streichen',
      );
    }

    // Compare unmatched custom items against the "Sonstige" reference,
    // scaled by the city's service level (sonstige = a service category).
    final sonstigeBenchmark = RemoteConfig.instance.nat('sonstige', 0.06) *
        RemoteConfig.instance.factorFor(city, 'sonstige');
    final ratio = perSqmMonth / sonstigeBenchmark;
    if (ratio >= highThreshold) {
      final pct = ((ratio - 1) * 100).round();
      return PositionResult(
        name: name,
        amount: item.amount,
        perSqmMonth: perSqmMonth,
        benchmark: sonstigeBenchmark,
        ratio: ratio,
        verdict: Verdict.elevated,
        excess: item.amount - sonstigeBenchmark * divisor,
        note: tr(
          'Unusually high for an "other costs" item (about $pct% above the reference value). It must be itemized and agreed in your lease.',
          'Ungewöhnlich hoch für eine sonstige Position (rund $pct % über dem Referenzwert). Sie muss aufgeschlüsselt und im Mietvertrag vereinbart sein.',
        ),
        letterReason:
            'ist ungewöhnlich hoch für eine sonstige Betriebskostenposition und bedarf einer mietvertraglichen Grundlage',
      );
    }

    return PositionResult(
      name: name,
      amount: item.amount,
      perSqmMonth: perSqmMonth,
      benchmark: sonstigeBenchmark,
      ratio: ratio,
      verdict: Verdict.ok,
      excess: 0,
      note: tr(
        'Check that this item is listed in your lease as a chargeable cost.',
        'Prüfen Sie, ob diese Position im Mietvertrag als umlagefähig vereinbart ist.',
      ),
      letterReason: '',
    );
  }
}
