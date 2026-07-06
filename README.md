# NebenCheck

A Flutter app that audits a German **Nebenkostenabrechnung** (annual operating-cost statement). Tenant associations estimate that roughly every second statement contains at least one error, but checking one today means paying a human-review service. NebenCheck makes the check self-serve: copy the numbers from the paper statement, get a verdict per line, and generate a formal German objection letter (Widerspruch) in one tap.

> University prototype. Benchmark values approximate the Deutscher Mieterbund (DMB) Betriebskostenspiegel. This is not legal advice.

## Quick start

The zip contains the Dart source and manifest only. Platform folders (android/, ios/) are generated locally:

```bash
cd nebencheck
flutter create .        # generates android/ios folders, keeps lib/ and pubspec.yaml
flutter pub get
flutter run
```

Requires Flutter 3.19+ (Dart 3.3+). Run the unit tests with `flutter test`.

Tap **"See a demo analysis"** on the home screen for an instant walkthrough with realistic sample data (a 62 m² flat with several problems hidden inside).

## What it checks

**1. Benchmark findings.** Each of the 16 cost categories from § 2 BetrKV is converted to € per m² per month and compared with a national reference value (see `lib/data/benchmarks.dart`). Ratios ≥ 1.25× are flagged as *above average*, ≥ 1.6× as *far above average*, and the questionable excess amount is summed into a savings estimate.

**2. Legal findings.** Formal rules that can invalidate a charge regardless of its size:

| Check | Rule |
|---|---|
| 12-month delivery deadline | § 556 Abs. 3 BGB — a late statement generally voids back-payment demands |
| Billing period ≤ 12 months | § 556 Abs. 3 BGB |
| 12-month objection window | § 556 Abs. 3 Satz 5 BGB — with a live countdown |
| Non-apportionable costs | § 1 Abs. 2 BetrKV — keyword scan flags administration, repairs, reserves, banking fees etc. |
| Cable TV | TKG reform — not chargeable for periods after 30 June 2024 (end of the "Nebenkostenprivileg") |
| Heating split | Heizkostenverordnung — at least 50% must be billed by consumption (manual checklist item) |

**3. The letter.** `lib/logic/letter_generator.dart` assembles a formal German Widerspruch: it lists every flagged position with a legal reason, requests receipt inspection (§ 259 BGB), declares payment under reserve, and sets a reply deadline. The app UI is English; the letter is German because its recipient is.

## Architecture

```
lib/
  models/models.dart        pure-Dart domain models (no Flutter imports)
  data/benchmarks.dart      reference values + legal keyword lists
  data/samples.dart         empty + demo statement factories
  logic/analyzer.dart       the audit engine (unit-tested)
  logic/letter_generator.dart
  state/app_state.dart      ChangeNotifier (provider)
  util/format.dart          German number/date formatting, month math
  ui/common.dart            SurfaceCard, VerdictChip, BenchmarkBar, field styles
  screens/                  home → statement form → positions → results → letter
  theme.dart                design tokens
  main.dart
test/
  analyzer_test.dart        deadline, benchmark and BetrKV keyword tests
```

Business logic is pure Dart, so `flutter test` runs headless and fast. State is a single `AppState` provided at the root.

## Design

"German paperwork, modern audit": cool form-gray background, Prussian-blue primary, and stamp-like verdict colors — warm tones for price problems, violet for legal violations (a different *kind* of wrong). Euro amounts render in a mono face like a printed ledger. The signature element is the **BenchmarkBar** under every position: the dark tick in the middle is the national average, the fill shows where the statement lands.

## Roadmap

- OCR the paper statement with `google_mlkit_text_recognition` instead of manual entry
- City-level benchmarks (Betriebskostenspiegel values differ strongly by region)
- PDF export of the letter (`pdf` + `printing` packages)
- German localization of the UI (`flutter_localizations`)
- Persist past checks locally (`shared_preferences` or `drift`)
