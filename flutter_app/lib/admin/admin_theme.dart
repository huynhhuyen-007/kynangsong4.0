import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminTheme {
  // ── Theme Toggle ─────────────────────────────────────────────────────────
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

  static void toggleTheme() {
    themeNotifier.value = themeNotifier.value == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
  }

  static bool get isDark => themeNotifier.value == ThemeMode.dark;

  // ── Dark Color Palette (GitHub Dark Industrial) ──────────────────────────
  static const Color bg        = Color(0xFF0D1117);
  static const Color surface   = Color(0xFF161B22);
  static const Color card      = Color(0xFF21262D);
  static const Color border    = Color(0xFF30363D);
  static const Color textPrimary   = Color(0xFFE6EDF3);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted     = Color(0xFF484F58);

  // ── Accent palette ───────────────────────────────────────────────────────
  static const Color blue    = Color(0xFF58A6FF);
  static const Color green   = Color(0xFF3FB950);
  static const Color red     = Color(0xFFF78166);
  static const Color orange  = Color(0xFFD29922);
  static const Color purple  = Color(0xFFBC8CFF);

  // ── Dark Theme ───────────────────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: blue,
      secondary: green,
      error: red,
      surface: surface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    ),
    cardTheme: CardThemeData(
      color: card, elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: border, width: 1),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: surface, surfaceTintColor: Colors.transparent,
      foregroundColor: textPrimary, elevation: 0,
      titleTextStyle: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
      iconTheme: const IconThemeData(color: textSecondary),
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 0),
    inputDecorationTheme: _inputTheme(bg),
    elevatedButtonTheme: _elevatedBtn(),
    textButtonTheme: _textBtn(),
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: textSecondary)),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: surface,
      indicatorColor: blue.withOpacity(0.15),
      selectedIconTheme: const IconThemeData(color: blue),
      unselectedIconTheme: const IconThemeData(color: textSecondary),
      selectedLabelTextStyle: GoogleFonts.outfit(color: blue, fontWeight: FontWeight.w700, fontSize: 12),
      unselectedLabelTextStyle: GoogleFonts.outfit(color: textSecondary, fontSize: 12),
      elevation: 0, useIndicator: true,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: card, elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: border),
      ),
      textStyle: GoogleFonts.outfit(color: textPrimary, fontSize: 14),
    ),
  );

  // ── Light Color Palette ─────────────────────────────────────────────────
  static const Color _lightBg     = Color(0xFFF6F8FA);
  static const Color _lightSurf   = Color(0xFFFFFFFF);
  static const Color _lightCard   = Color(0xFFFFFFFF);
  static const Color _lightBorder = Color(0xFFD0D7DE);
  static const Color _lightText   = Color(0xFF111111);  // primary — WCAG AA
  static const Color _lightSub    = Color(0xFF444444);  // secondary
  static const Color _lightHint   = Color(0xFF777777);  // metadata/hint

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: _lightBg,
    colorScheme: const ColorScheme.light(
      primary: blue,
      secondary: green,
      error: red,
      surface: _lightSurf,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _lightText,
      onSurfaceVariant: _lightSub,
      outline: _lightBorder,
      outlineVariant: Color(0xFFE8ECF0),
    ),
    textTheme: GoogleFonts.outfitTextTheme().apply(
      bodyColor: _lightText,
      displayColor: _lightText,
    ),
    cardTheme: CardThemeData(
      color: _lightCard, elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _lightBorder, width: 1),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _lightSurf, surfaceTintColor: Colors.transparent,
      foregroundColor: _lightText, elevation: 0,
      shadowColor: _lightBorder,
      titleTextStyle: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: _lightText),
      iconTheme: const IconThemeData(color: _lightSub),
    ),
    dividerTheme: const DividerThemeData(color: _lightBorder, thickness: 1, space: 0),
    inputDecorationTheme: _inputTheme(_lightBg, borderColor: _lightBorder),
    elevatedButtonTheme: _elevatedBtn(),
    textButtonTheme: _textBtn(),
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: _lightSub)),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: _lightSurf,
      indicatorColor: blue.withOpacity(0.12),
      selectedIconTheme: const IconThemeData(color: blue),
      unselectedIconTheme: IconThemeData(color: _lightSub),
      selectedLabelTextStyle: GoogleFonts.outfit(color: blue, fontWeight: FontWeight.w700, fontSize: 12),
      unselectedLabelTextStyle: GoogleFonts.outfit(color: _lightSub, fontSize: 12),
      elevation: 0, useIndicator: true,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: _lightSurf, elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: _lightBorder),
      ),
      textStyle: GoogleFonts.outfit(color: _lightText, fontSize: 14),
    ),
  );

  static InputDecorationTheme _inputTheme(Color fill, {Color borderColor = border}) =>
    InputDecorationTheme(
      filled: true, fillColor: fill,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: blue, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      hintStyle: GoogleFonts.outfit(fontSize: 14),
      labelStyle: GoogleFonts.outfit(fontSize: 14),
    );

  static ElevatedButtonThemeData _elevatedBtn() => ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: blue, foregroundColor: Colors.white, elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
    ),
  );

  static TextButtonThemeData _textBtn() => TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: blue,
      textStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
    ),
  );
}
