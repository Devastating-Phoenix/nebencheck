import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme.dart';
import '../util/l10n.dart';

/// A field box on the form: flat off-white panel with a printed
/// hairline border. Forms are flat — no shadows, minimal radius.
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppColors.line),
      ),
      child: child,
    );
  }
}

/// Form-section head: green uppercase label with a printed rule
/// running to the right edge, like "ABSCHNITT 2" on a Steuerformular.
class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Row(
        children: [
          Text(text.toUpperCase(), style: AppText.label()),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 0.8,
              color: AppColors.primary.withOpacity(0.35),
            ),
          ),
        ],
      ),
    );
  }
}

Color verdictColor(Verdict v) {
  switch (v) {
    case Verdict.ok:
      return AppColors.ok;
    case Verdict.elevated:
      return AppColors.elevated;
    case Verdict.high:
      return AppColors.high;
    case Verdict.notApportionable:
      return AppColors.legal;
  }
}

Color verdictBg(Verdict v) {
  switch (v) {
    case Verdict.ok:
      return AppColors.okBg;
    case Verdict.elevated:
      return AppColors.elevatedBg;
    case Verdict.high:
      return AppColors.highBg;
    case Verdict.notApportionable:
      return AppColors.legalBg;
  }
}

String verdictLabel(Verdict v) {
  switch (v) {
    case Verdict.ok:
      return tr('Normal', 'Normal');
    case Verdict.elevated:
      return tr('Worth checking', 'Prüfenswert');
    case Verdict.high:
      return tr('Objection likely', 'Deutlich überhöht');
    case Verdict.notApportionable:
      return tr('Not chargeable §', 'Nicht umlagefähig §');
  }
}

/// The signature element: a rubber stamp. Slightly rotated, double
/// border, uppercase condensed — pressed onto the form with a short
/// scale-settle when it first appears. Respects reduced motion.
class Stamp extends StatelessWidget {
  final String text;
  final Color color;
  final double size;

  const Stamp(
    this.text, {
    super.key,
    required this.color,
    this.size = 12.5,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final stamp = Transform.rotate(
      angle: -0.038,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: color.withOpacity(0.85), width: 1.8),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.55), width: 0.8),
          ),
          child: Text(
            text.toUpperCase(),
            textAlign: TextAlign.center,
            softWrap: false,
            style: TextStyle(
              color: color.withOpacity(0.92),
              fontSize: size,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
              height: 1.25,
            ),
          ),
        ),
      ),
    );
    if (reduceMotion) return stamp;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 1.45 - 0.45 * t, child: child),
      ),
      child: stamp,
    );
  }
}

/// Verdict stamp used on position cards.
class VerdictChip extends StatelessWidget {
  final Verdict verdict;

  const VerdictChip(this.verdict, {super.key});

  @override
  Widget build(BuildContext context) {
    return Stamp(verdictLabel(verdict), color: verdictColor(verdict));
  }
}

/// Signature gauge: a printed ruler line comparing this statement's
/// €/m²/month with the national benchmark. The ink tick in the middle
/// *is* the benchmark; the drawn bar shows where this statement lands
/// (2× benchmark fills the whole ruler).
class BenchmarkBar extends StatelessWidget {
  final double ratio;
  final Color color;

  const BenchmarkBar({super.key, required this.ratio, required this.color});

  @override
  Widget build(BuildContext context) {
    final fill = (ratio / 2).clamp(0.05, 1.0).toDouble();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      return SizedBox(
        height: 16,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Ruler baseline with end ticks.
            Positioned(
              top: 7,
              child: Container(width: w, height: 1.2, color: AppColors.line),
            ),
            Positioned(
              left: 0,
              top: 3,
              child: Container(width: 1.2, height: 9, color: AppColors.line),
            ),
            Positioned(
              right: 0,
              top: 3,
              child: Container(width: 1.2, height: 9, color: AppColors.line),
            ),
            // The drawn value bar.
            TweenAnimationBuilder<double>(
              tween: Tween(begin: reduceMotion ? fill : 0, end: fill),
              duration: const Duration(milliseconds: 550),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Positioned(
                top: 5,
                child: Container(
                  width: w * value,
                  height: 5,
                  color: color.withOpacity(0.9),
                ),
              ),
            ),
            // Benchmark tick in typewriter ink.
            Positioned(
              left: w / 2 - 1,
              top: 0,
              child: Container(width: 2, height: 16, color: AppColors.ink),
            ),
          ],
        ),
      );
    });
  }
}

/// Shared text-field decoration (kept out of ThemeData for
/// cross-version compatibility). Square form fields, green labels.
InputDecoration fieldDecoration(String label, {String? hint, String? suffix}) {
  OutlineInputBorder border(Color c, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(3),
        borderSide: BorderSide(color: c, width: width),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    suffixText: suffix,
    filled: true,
    fillColor: AppColors.cardDeep,
    labelStyle: const TextStyle(
      color: AppColors.primary,
      fontWeight: FontWeight.w600,
      fontSize: 14.5,
      letterSpacing: 0.3,
    ),
    hintStyle: TextStyle(color: AppColors.inkSoft.withOpacity(0.6)),
    suffixStyle: const TextStyle(color: AppColors.inkSoft),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: border(AppColors.lineStrong),
    enabledBorder: border(AppColors.lineStrong),
    focusedBorder: border(AppColors.primary, 1.6),
  );
}
