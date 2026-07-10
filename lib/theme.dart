import 'package:flutter/material.dart';

/// Design tokens: "Der Prüfbogen" — the German audit form.
///
/// The app is styled as an official German form: gray-green paper,
/// form furniture (rules, boxes, labels) printed in Amtsgrün like a
/// Steuerformular, the user's data typed in typewriter black, and
/// verdicts applied as rubber stamps. Overcharges are marked with the
/// auditor's red pencil; legal findings use classic violet stamp ink —
/// a different *kind* of wrong. Euro amounts render in Courier like a
/// typed entry (see [AppText.mono]).
class AppColors {
  static const paper = Color(0xFFEEEDE3); // gray-green form paper
  static const paperDeep = Color(0xFFD3D2C4); // the desk under the sheet
  static const card = Color(0xFFFBFAF2); // field boxes on the form
  static const cardDeep = Color(0xFFFDFCF7); // input wells
  static const ink = Color(0xFF22211C); // typewriter ink
  static const inkSoft = Color(0xFF676558); // pencil annotations
  static const line = Color(0xFFC9C7B7); // printed hairline rules
  static const lineStrong = Color(0xFFB0AE9C);
  static const primary = Color(0xFF2F6A4F); // Amtsgrün — form print
  static const primaryBright = Color(0xFF3E7A5D);
  static const primaryDark = Color(0xFF24523D);
  static const onPrimary = Color(0xFFF4F3E9);

  // Verdict stamp inks.
  static const ok = Color(0xFF2F6A4F);
  static const okBg = Color(0xFFE0E8DC);
  static const elevated = Color(0xFF9A7B0A); // amber — worth checking
  static const elevatedBg = Color(0xFFF0E7C6);
  static const high = Color(0xFFB23A2E); // the auditor's red pencil
  static const highBg = Color(0xFFF1DCD6);
  static const legal = Color(0xFF5B4A9E); // violet stamp ink
  static const legalBg = Color(0xFFE3DFEF);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      surface: AppColors.paper,
      onSurface: AppColors.ink,
      outline: AppColors.lineStrong,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.paper,
    // Fonts are bundled assets (see pubspec) — nothing is fetched from
    // Google at runtime.
    textTheme: base.textTheme.apply(
      fontFamily: 'Barlow',
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.paper,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.ink,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        fontFamily: 'BarlowCondensed',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: AppColors.ink,
      ),
    ),
    dividerColor: AppColors.line,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.ink,
      contentTextStyle: const TextStyle(
        fontFamily: 'Barlow',
        color: AppColors.paper,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    dialogTheme: base.dialogTheme.copyWith(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: AppColors.lineStrong),
      ),
    ),
    datePickerTheme: base.datePickerTheme.copyWith(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      headerForegroundColor: AppColors.ink,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        textStyle: const TextStyle(
          fontFamily: 'BarlowCondensed',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.6,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: AppColors.primary, width: 1.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        textStyle: const TextStyle(
          fontFamily: 'BarlowCondensed',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.6,
        ),
      ),
    ),
  );
}

/// Text helpers used across screens.
class AppText {
  /// Typewriter face for everything "entered into the form":
  /// € figures, dates, scores, line numbers, the letter.
  static TextStyle mono({
    double size = 15,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.ink,
  }) =>
      TextStyle(
        fontFamily: 'CourierPrime',
        fontSize: size,
        fontWeight: weight,
        color: color,
      );

  /// Condensed DIN-style display for headlines and form heads.
  static TextStyle display({double size = 30, Color color = AppColors.ink}) =>
      TextStyle(
        fontFamily: 'BarlowCondensed',
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: 1.02,
        letterSpacing: 0.2,
        color: color,
      );

  /// Small uppercase form label, printed in Amtsgrün.
  static TextStyle label({Color color = AppColors.primary}) =>
      TextStyle(
        fontFamily: 'BarlowCondensed',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 2.2,
        color: color,
      );
}
