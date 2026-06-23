import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Theme mode provider ───────────────────────────────────
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDark') ?? true;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    _applySystemUI(isDark);
  }

  Future<void> toggle() async {
    final nowDark = state == ThemeMode.dark;
    final nextDark = !nowDark;
    state = nextDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', nextDark);
    _applySystemUI(nextDark);
  }

  bool get isDark => state == ThemeMode.dark;

  void _applySystemUI(bool isDark) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: isDark ? const Color(0xFF12121E) : const Color(0xFFFFF8F3),
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));
  }
}

// ── Static colour tokens (dark = purple, light = coral) ───
class WTheme {
  // Dark tokens
  static const Color bg          = Color(0xFF0A0A12);
  static const Color bg2         = Color(0xFF12121E);
  static const Color bg3         = Color(0xFF1A1A28);
  static const Color card        = Color(0xFF1E1E2E);
  static const Color border      = Color(0xFF2A2A3E);
  static const Color borderLight = Color(0xFF363650);
  static const Color purple      = Color(0xFF7C6EFF);
  static const Color purple2     = Color(0xFF9D91FF);
  static const Color purpleGlow  = Color(0x337C6EFF);
  static const Color purpleSoft  = Color(0xFF2D2548);
  static const Color pink        = Color(0xFFF472B6);
  static const Color green       = Color(0xFF4ADE80);
  static const Color amber       = Color(0xFFFCD34D);
  static const Color red         = Color(0xFFF87171);
  static const Color blue        = Color(0xFF60A5FA);
  static const Color textPrimary    = Color(0xFFE8E8F4);
  static const Color textSecondary  = Color(0xFFA0A0C0);
  static const Color textMuted      = Color(0xFF6060A0);

  // Light / warm tokens
  static const Color lBg          = Color(0xFFFFF8F3);
  static const Color lBg2         = Color(0xFFFFF0E8);
  static const Color lBg3         = Color(0xFFFFE4D4);
  static const Color lCard        = Color(0xFFFFFFFF);
  static const Color lBorder      = Color(0xFFFFD5BE);
  static const Color lPrimary     = Color(0xFFFF6B35);
  static const Color lPrimary2    = Color(0xFFFF8C5A);
  static const Color lPrimarySoft = Color(0xFFFFEDE6);
  static const Color lText        = Color(0xFF1A0A00);
  static const Color lTextSec     = Color(0xFF6B3A2A);
  static const Color lTextMuted   = Color(0xFFB07050);

  static const List<Color> avatarColors = [
    Color(0xFF7C6EFF), Color(0xFFFF6B35), Color(0xFF4ADE80),
    Color(0xFFFCD34D), Color(0xFFF87171), Color(0xFF60A5FA),
    Color(0xFFA78BFA), Color(0xFF34D399), Color(0xFFFB923C),
  ];

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF7C6EFF), Color(0xFFA855F7)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF3CAC)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF0A0A12), Color(0xFF0D0A1A)],
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
  );
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E1E2E), Color(0xFF16162A)],
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
  );

  static ThemeData get dark  => _build(isDark: true);
  static ThemeData get light => _build(isDark: false);

  static ThemeData _build({required bool isDark}) {
    final bg_       = isDark ? bg    : lBg;
    final bg2_      = isDark ? bg2   : lBg2;
    final bg3_      = isDark ? bg3   : lBg3;
    final card_     = isDark ? card  : lCard;
    final border_   = isDark ? border: lBorder;
    final primary_  = isDark ? purple: lPrimary;
    // ignore: unused_local_variable
    final primary2_ = isDark ? purple2: lPrimary2;
    // ignore: unused_local_variable
    final soft_     = isDark ? purpleSoft: lPrimarySoft;
    final tPrimary_ = isDark ? textPrimary  : lText;
    final tSec_     = isDark ? textSecondary: lTextSec;
    final tMuted_   = isDark ? textMuted    : lTextMuted;
    final br        = isDark ? Brightness.dark : Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: br,
      scaffoldBackgroundColor: bg_,
      colorScheme: ColorScheme(
        brightness: br,
        primary: primary_, secondary: isDark ? pink : const Color(0xFFFF3CAC),
        surface: card_, background: bg_,
        onPrimary: Colors.white, onSecondary: Colors.white,
        onSurface: tPrimary_, onBackground: tPrimary_,
        error: isDark ? red : const Color(0xFFDC2626), onError: Colors.white,
        outline: border_,
      ),
      textTheme: TextTheme(
        displayLarge:  GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: tPrimary_, letterSpacing: -1),
        displayMedium: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w700, color: tPrimary_, letterSpacing: -0.5),
        displaySmall:  GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: tPrimary_),
        headlineMedium:GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: tPrimary_),
        headlineSmall: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: tPrimary_),
        titleLarge:    GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: tPrimary_),
        titleMedium:   GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: tPrimary_),
        bodyLarge:     GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, color: tPrimary_, height: 1.6),
        bodyMedium:    GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: tSec_, height: 1.5),
        bodySmall:     GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400, color: tMuted_),
        labelLarge:    GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: tPrimary_),
        labelMedium:   GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: tSec_),
        labelSmall:    GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: tMuted_, letterSpacing: 0.5),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg2_, elevation: 0, scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: tPrimary_),
        iconTheme: IconThemeData(color: tSec_),
      ),
      cardTheme: CardThemeData(
        color: card_, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: border_)),
      ),
      dividerTheme: DividerThemeData(color: border_, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: bg3_,
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: border_)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: border_)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primary_, width: 1.5)),
        hintStyle: GoogleFonts.inter(color: tMuted_, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary_, foregroundColor: Colors.white, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: bg3_, side: BorderSide(color: border_),
        labelStyle: GoogleFonts.inter(fontSize: 12, color: tSec_),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((s) => s.contains(MaterialState.selected) ? primary_ : tMuted_),
        trackColor: MaterialStateProperty.resolveWith((s) => s.contains(MaterialState.selected) ? primary_.withOpacity(0.4) : border_),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card_,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

// ── Context extension for adaptive colours ─────────────────
extension WThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get wBg         => isDark ? WTheme.bg         : WTheme.lBg;
  Color get wBg2        => isDark ? WTheme.bg2        : WTheme.lBg2;
  Color get wBg3        => isDark ? WTheme.bg3        : WTheme.lBg3;
  Color get wCard       => isDark ? WTheme.card       : WTheme.lCard;
  Color get wBorder     => isDark ? WTheme.border     : WTheme.lBorder;
  Color get wPrimary    => isDark ? WTheme.purple     : WTheme.lPrimary;
  Color get wPrimary2   => isDark ? WTheme.purple2    : WTheme.lPrimary2;
  Color get wSoft       => isDark ? WTheme.purpleSoft : WTheme.lPrimarySoft;
  Color get wText       => isDark ? WTheme.textPrimary    : WTheme.lText;
  Color get wTextSec    => isDark ? WTheme.textSecondary  : WTheme.lTextSec;
  Color get wTextMuted  => isDark ? WTheme.textMuted      : WTheme.lTextMuted;
  Color get wRed        => isDark ? WTheme.red   : const Color(0xFFDC2626);
  Color get wGreen      => isDark ? WTheme.green : const Color(0xFF16A34A);

  LinearGradient get wGradient => isDark ? WTheme.purpleGradient : WTheme.warmGradient;
}
