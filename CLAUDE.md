# NebenCheck — CLAUDE.md

Flutter **web** app that audits German operating-cost statements (Nebenkostenabrechnungen).
Live at https://nebencheck-ten.vercel.app. Flutter SDK: `D:\flutter`.

## Definition of done

A change is DONE only when ALL of these pass. "Looks complete" is not done.

1. `flutter analyze --fatal-infos` — zero issues (CI enforces this, infos count as failures).
2. `flutter test` — green, including the tests for any logic you touched.
3. New/changed logic in `lib/logic/` or `lib/util/` has tests in `test/` covering it.
4. Work is on a branch with a PR — **main is branch-protected; never commit to main.**
5. UI changes: verified in a real browser render (headless Chrome screenshot — the
   in-app Browser pane hangs on this machine).

## Verify commands

```
D:\flutter\bin\flutter analyze --fatal-infos
D:\flutter\bin\flutter test
```

## Stop conditions for autonomous work

- Max **3 attempts** at fixing a failing test/analyzer error. On the 3rd failure,
  stop and report the full error output — do not attempt a 4th approach.
- Never weaken or delete an existing test to make a change pass. If a test blocks
  you, stop and explain why.
- Do not touch `web/`, Vercel config, or CI workflows unless the task is about them.

## Domain constraints (why tests look the way they do)

- Legal logic is load-bearing: § 556 Abs. 3 BGB (deadlines), § 12 HeizKV (15 % cut),
  § 1 Abs. 2 BetrKV (non-apportionable). Changes here need a cited source.
- The objection letter is always German regardless of UI language.
- `lib/logic/`, `lib/models/`, `lib/util/format.dart` are pure Dart (no Flutter
  imports) so tests run headless — keep it that way.
