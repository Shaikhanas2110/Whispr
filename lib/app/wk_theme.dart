import 'package:flutter/material.dart';

class WKTheme {
  WKTheme._();

  // ── Core palette ──────────────────────────────────────────────
  // Sleek, professional dark mode backgrounds
  static const Color bgWarm =
      Color(0xFF0F111A); // Main page background (Obsidian)
  static const Color bgWarmDeep =
      Color(0xFF0A0C14); // slightly darker background
  static const Color bgCard = Color(0xFF161925); // Card surfaces
  static const Color bgCardWarm =
      Color(0xFF1F2336); // Tinted or active surfaces

  // Primary accent — Professional Indigo / Deep Violet
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primarySoft = Color(0xFF242747);

  // Crisp, glowing category colors optimized for dark backgrounds
  static const Color green = Color(0xFF34D399); // nature / wellness (minty)
  static const Color greenSoft = Color(0xFF112D24);
  static const Color blue = Color(0xFF38BDF8); // trending / news (sky blue)
  static const Color blueSoft = Color(0xFF122C3A);
  static const Color coral =
      Color(0xFFF87171); // confessions / drama (soft red/coral)
  static const Color coralSoft = Color(0xFF331C1C);
  static const Color purple =
      Color(0xFFC084FC); // mental health (lavender/purple)
  static const Color purpleSoft = Color(0xFF2E1A47);
  static const Color amber = Color(0xFFFBBF24); // humor / trending (amber/gold)
  static const Color amberSoft = Color(0xFF332912);
  static const Color teal = Color(0xFF2DD4BF); // career / life (teal)
  static const Color tealSoft = Color(0xFF102E2B);

  // Crisp text colors for deep contrast
  static const Color textPrimary = Color(0xFFF3F4F6); // Crisp off-white
  static const Color textSecondary = Color(0xFF9CA3AF); // Cool gray
  static const Color textMuted = Color(0xFF6B7280); // Muted gray
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Border / divider (subtle cool borders)
  static const Color border = Color(0xFF242838);
  static const Color divider = Color(0xFF1D2130);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);

  // ── Community color map ───────────────────────────────────────
  static Color communityColor(String id) {
    const map = {
      'confessions': coral,
      'relationships': Color(0xFFF472B6), // Pinkish rose tint
      'mental_health': purple,
      'career': teal,
      'humor': amber,
      'wellness': green,
      'trending': blue,
      'news': blue,
    };
    return map[id] ?? primary;
  }

  static Color communitySoft(String id) {
    const map = {
      'confessions': coralSoft,
      'relationships': Color(0xFF331B26),
      'mental_health': purpleSoft,
      'career': tealSoft,
      'humor': amberSoft,
      'wellness': greenSoft,
      'trending': blueSoft,
      'news': blueSoft,
    };
    return map[id] ?? primarySoft;
  }

  // ── Radius ─────────────────────────────────────────────────────
  static const double radiusSm = 10;
  static const double radiusMd = 16;
  static const double radiusLg = 22;
  static const double radiusXl = 30;

  // ── Shadows (subtle dark depth glows) ──────────────────────────
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> pillShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // ── Helper: decoration for a dark card ──────────────────────
  static BoxDecoration cardDecoration({
    Color? color,
    double radius = radiusMd,
    bool showBorder = true,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: color ?? bgCard,
      borderRadius: BorderRadius.circular(radius),
      border: showBorder ? Border.all(color: border, width: 1) : null,
      boxShadow: shadows ?? cardShadow,
    );
  }

  // ── Helper: category pill ────────────────────────────────────
  static Widget categoryPill({
    required String label,
    required Color color,
    Color? bgColor,
    double fontSize = 11,
    EdgeInsets padding =
        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor ?? color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ── Theme builder ─────────────────────────────────────────────
ThemeData buildKidoryTheme({bool dark = true}) {
  // Now explicitly configured as a Dark Theme
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: WKTheme.bgWarm,
    colorScheme: const ColorScheme.dark(
      primary: WKTheme.primary,
      secondary: WKTheme.green,
      surface: WKTheme.bgCard,
      error: WKTheme.error,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: WKTheme.bgWarm,
      foregroundColor: WKTheme.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: WKTheme.textSecondary),
      titleTextStyle: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: WKTheme.textPrimary,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: WKTheme.textPrimary,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: WKTheme.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: WKTheme.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: WKTheme.textPrimary,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: WKTheme.textPrimary,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: WKTheme.textPrimary,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: WKTheme.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        height: 1.65,
        color: WKTheme.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 13,
        height: 1.5,
        color: WKTheme.textSecondary,
      ),
      bodySmall: TextStyle(
        fontSize: 11,
        color: WKTheme.textMuted,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: WKTheme.textPrimary,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: WKTheme.textMuted,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: WKTheme.bgCard,
      hintStyle: const TextStyle(color: WKTheme.textMuted, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(WKTheme.radiusMd),
        borderSide: const BorderSide(color: WKTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(WKTheme.radiusMd),
        borderSide: const BorderSide(color: WKTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(WKTheme.radiusMd),
        borderSide: const BorderSide(color: WKTheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    dividerTheme: const DividerThemeData(
      color: WKTheme.divider,
      thickness: 1,
      space: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: WKTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WKTheme.radiusMd)),
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: WKTheme.primary,
        side: const BorderSide(color: WKTheme.primary),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WKTheme.radiusMd)),
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: WKTheme.bgCardWarm,
      contentTextStyle:
          const TextStyle(color: WKTheme.textPrimary, fontSize: 13),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WKTheme.radiusMd)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
