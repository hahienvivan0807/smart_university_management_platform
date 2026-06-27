import 'package:flutter/material.dart';

// ============================================================================
// DESIGN TOKENS  —  Notion / Linear / Slack inspired
// (Unchanged from the original FE prototype.)
// ============================================================================

/// Restrained neutral palette with a single indigo accent (Linear-style).
class AppColors {
  AppColors._();

  static const Color accent = Color(0xFF5B5BD6);
  static const Color accentHover = Color(0xFF6E6ADE);
  static const Color accentSoft = Color(0xFFEEEEFB);
  static const Color accentSoftDark = Color(0xFF26263A);

  static const Color lightCanvas = Color(0xFFFFFFFF);
  static const Color lightSidebar = Color(0xFFFAFAFA);
  static const Color lightPanel = Color(0xFFF7F7F8);
  static const Color lightBorder = Color(0xFFEBEBED);
  static const Color lightText = Color(0xFF1A1A1E);
  static const Color lightMuted = Color(0xFF6F6F78);
  static const Color lightFaint = Color(0xFF9A9AA3);

  static const Color darkCanvas = Color(0xFF101013);
  static const Color darkSidebar = Color(0xFF0B0B0E);
  static const Color darkPanel = Color(0xFF18181C);
  static const Color darkBorder = Color(0xFF26262B);
  static const Color darkText = Color(0xFFEDEDEF);
  static const Color darkMuted = Color(0xFF9B9BA4);
  static const Color darkFaint = Color(0xFF6A6A73);

  static const Color green = Color(0xFF3FB950);
  static const Color amber = Color(0xFFD29922);
  static const Color red = Color(0xFFE5534B);
  static const Color blue = Color(0xFF388BFD);
  static const Color purple = Color(0xFF986EE2);
  static const Color teal = Color(0xFF2DB7A3);
  static const Color muted2 = Color(0xFF9A9AA3);
}

class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 18;
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 44;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.accent,
      surface: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      fontFamily: 'Inter',
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      textTheme: _textTheme(isDark),
    );
  }

  static TextTheme _textTheme(bool isDark) {
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    return TextTheme(
      displaySmall: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: text,
      ),
      headlineSmall: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        color: text,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: text,
      ),
      bodyLarge: TextStyle(
        fontSize: 14.5,
        height: 1.45,
        letterSpacing: -0.1,
        color: text,
      ),
      bodyMedium: TextStyle(
        fontSize: 13.5,
        height: 1.45,
        color: muted,
      ),
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: muted,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: muted,
      ),
    );
  }
}

/// Theme-aware palette helpers.
extension Palette on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get canvas => isDark ? AppColors.darkCanvas : AppColors.lightCanvas;
  Color get sidebar => isDark ? AppColors.darkSidebar : AppColors.lightSidebar;
  Color get panel => isDark ? AppColors.darkPanel : AppColors.lightPanel;
  Color get border => isDark ? AppColors.darkBorder : AppColors.lightBorder;
  Color get text => isDark ? AppColors.darkText : AppColors.lightText;
  Color get muted => isDark ? AppColors.darkMuted : AppColors.lightMuted;
  Color get faint => isDark ? AppColors.darkFaint : AppColors.lightFaint;
  Color get accentSoft =>
      isDark ? AppColors.accentSoftDark : AppColors.accentSoft;
}
