# NebenCheck

Audit your German **Nebenkostenabrechnung** (annual operating-cost statement)
against national benchmarks and tenancy law, then generate a formal objection
letter — self-serve, in about three minutes.

**Live:** https://nebencheck-ten.vercel.app

Tenant associations estimate that roughly every second statement contains at
least one error, but checking one today means paying a human-review service.
NebenCheck makes it self-serve: copy the numbers from the paper statement, get a
traffic-light verdict per line adjusted to your city's cost level, and generate
a ready-to-send German objection letter (Widerspruch) as a PDF. Everything runs
in your browser — no statement data is uploaded anywhere.

> University prototype. Reference values approximate the DMB Betriebskostenspiegel,
> adjusted to your selected city. This is **not legal advice**.

---

## Contributing a data correction

The benchmark values and city factors are the heart of the app, and they go
stale as new surveys are published. **If a number looks wrong or out of date,
please fix it — that's why this repo is public.**

All the data lives in two plain files:

| File | What's in it |
|------|--------------|
| [`lib/data/benchmarks.dart`](lib/data/benchmarks.dart) | National reference values per cost category (€/m²/month), from the DMB Betriebskostenspiegel |
| [`lib/data/cities.dart`](lib/data/cities.dart) | Per-city factors: `serviceFactor` (DMB state-level totals) and `feeFactor` (Haus & Grund / IW Nebenkostenranking) |

To propose a change:

1. **Open an issue** naming the value you think is wrong and cite a source (a DMB
   or Haus & Grund publication, a municipal fee schedule, etc.), **or**
2. **Open a pull request** editing the value directly, with the source in the PR
   description so a reviewer can verify it.

Every value should be traceable to a published figure. Interpolations are allowed
where no published value exists, but they must be marked as estimates (see the
`note` fields in `cities.dart`).

The live app reads its values from [`references.json`](references.json) (fetched
from this branch at startup), falling back to the compiled Dart defaults if that
file is unreachable. **A merged change to `references.json` goes live within
minutes — no app rebuild.** A scheduled GitHub Action
([`betriebskosten-watch.yml`](.github/workflows/betriebskosten-watch.yml)) also
watches for a newer DMB Betriebskostenspiegel and opens a PR with the proposed
numbers for review.

---

## What it checks

**1. Benchmark findings.** Each cost category from § 2 BetrKV is converted to €
per m² per month and compared with a city-adjusted reference value. Ratios
≥ 1.25× are flagged 🟡 *worth checking*, ≥ 1.6× 🔴 *objection likely*, and the
questionable excess is summed into a savings estimate. Municipal charges
(property tax, water, waste) scale by the local fee level; building services
(caretaker, cleaning, garden) scale by regional wages; heating and insurance are
national and never scaled.

**2. Legal findings.** Formal rules that can invalidate a charge regardless of size:

| Check | Rule |
|---|---|
| 12-month delivery deadline | § 556 Abs. 3 BGB — a late statement generally voids back-payment demands |
| Billing period ≤ 12 months | § 556 Abs. 3 BGB |
| 12-month objection window | § 556 Abs. 3 Satz 5 BGB — with a live countdown |
| Non-apportionable costs | § 1 Abs. 2 BetrKV — flags administration, repairs, reserves, banking fees |
| Cable TV | TKG reform — not chargeable for periods after 30 June 2024 |
| Heating split | § 12 HeizKV — flat-rate-only billing entitles a 15% cut |

**3. The letter.** `lib/logic/letter_generator.dart` assembles a formal German
Widerspruch citing each flagged position, requests receipt inspection (§ 259 BGB),
declares payment under reserve, and sets a reply deadline. Downloadable as a
DIN-5008 PDF. The UI is available in English and German; the letter is always
German because its recipient is.

---

## Running locally

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel).

```bash
flutter pub get
flutter run -d chrome          # run in the browser
flutter test                   # run the unit tests
flutter build web --release    # deployable build in build/web
```

The analysis logic (`lib/logic/analyzer.dart`) and models are pure Dart, so
`flutter test` runs headless and fast.

```
lib/
  models/models.dart            pure-Dart domain models
  data/benchmarks.dart          national reference values  ← data corrections here
  data/cities.dart              per-city cost factors       ← and here
  logic/analyzer.dart           the audit engine (unit-tested)
  logic/letter_generator.dart   the Widerspruch generator
  logic/calendar.dart           .ics objection-deadline export
  state/app_state.dart          ChangeNotifier + local persistence
  util/l10n.dart                DE/EN string helper
  screens/                      home → form → positions → results → letter, + about
```

---

## Sources

- **DMB Betriebskostenspiegel** — https://mieterbund.de/service/checks-formulare/betriebskosten/betriebskostenspiegel/
- **Haus & Grund / IW Consult Nebenkostenranking** — https://www.hausundgrund.de/nebenkostenranking-die-100-groessten-staedte-im-vergleich

## License

[PolyForm Noncommercial License 1.0.0](LICENSE) — free to use, modify, and share
for **any non-commercial purpose** (personal use, study, non-profits, public
institutions). **Commercial use is not permitted** without a separate license
from the copyright holder, who reserves all commercial rights.

Contributions are welcome under the same terms: by opening a pull request you
agree your contribution is licensed under this license, and you grant the
project's copyright holder the right to use it (including commercially).
