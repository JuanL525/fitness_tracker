import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Tema dark premium — slate + neón esmeralda/azul.
class AppTheme {
  // Paleta exacta (Tailwind → Flutter)
  static const Color slate950 = Color(0xFF020617);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate100 = Color(0xFFF1F5F9);

  static const Color emerald400 = Color(0xFF34D399);
  static const Color emerald600 = Color(0xFF059669);
  static const Color blue400 = Color(0xFF60A5FA);
  static const Color rose500 = Color(0xFFF43F5E);

  static const double cardRadius = 24;
  static const double chipRadius = 16;
  static const EdgeInsets cardPadding =
      EdgeInsets.symmetric(horizontal: 24, vertical: 24);

  // Alias de compatibilidad para widgets legacy
  static const Color stepsAccent = blue400;
  static const Color gpsAccent = blue400;
  static const Color monitorAccent = emerald400;
  static const Color ink = slate100;
  static const Color inkMuted = slate400;
  static const Color canvas = slate950;
  static const Color orange = emerald400;
  static const Color blue = blue400;
  static const Color cyan = blue400;
  static const Color green = emerald400;
  static const Color red = rose500;
  static const Color stepsBg = slate900;
  static const Color orangeBg = slate900;
  static const Color redBg = slate900;
  static const Color yellowBg = slate900;

  static BoxDecoration softCard({Color? borderColor}) =>
      cardDecoration(borderColor: borderColor);

  static const EdgeInsets screenPadding = EdgeInsets.all(20);

  static const Duration animFast = Duration(milliseconds: 350);
  static const Duration animMedium = Duration(milliseconds: 550);
  static const Curve animCurve = Curves.easeOutCubic;

  /// Meta diaria de pasos (solo UI).
  static const int dailyStepGoal = 10000;

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: emerald400,
      onPrimary: slate950,
      primaryContainer: emerald600,
      onPrimaryContainer: slate100,
      secondary: blue400,
      onSecondary: slate950,
      secondaryContainer: slate800,
      onSecondaryContainer: blue400,
      tertiary: blue400,
      error: rose500,
      onError: slate100,
      surface: slate950,
      onSurface: slate100,
      onSurfaceVariant: slate400,
      outline: slate800,
      outlineVariant: slate800,
      surfaceContainerHighest: slate900,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: slate950,
      cardColor: slate900,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: slate950,
        foregroundColor: slate100,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: slate100,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: slate900,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: slate800),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: emerald400,
          foregroundColor: slate950,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: slate900,
        labelStyle: const TextStyle(color: slate400),
        hintStyle: const TextStyle(color: slate500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: slate800),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: slate800),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: emerald400, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: slate900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: slate100,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: slate800,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: slate900,
        contentTextStyle: const TextStyle(color: slate100),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: emerald400,
        unselectedItemColor: slate500,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
          height: 1.05,
          color: slate100,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: slate100,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: slate100,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.55,
          color: slate400,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.5,
          color: slate400,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: slate400,
        ),
      ),
    );
  }

  static Color activityColor(String type) {
    switch (type) {
      case 'running':
        return emerald400;
      case 'walking':
        return blue400;
      default:
        return slate500;
    }
  }

  static Color activityBg(String type) {
    switch (type) {
      case 'running':
        return emerald400.withValues(alpha: 0.15);
      case 'walking':
        return blue400.withValues(alpha: 0.15);
      default:
        return slate800.withValues(alpha: 0.5);
    }
  }

  static IconData activityIcon(String type) {
    switch (type) {
      case 'walking':
        return Icons.directions_walk_rounded;
      case 'running':
        return Icons.directions_run_rounded;
      default:
        return Icons.self_improvement_rounded;
    }
  }

  static BoxDecoration cardDecoration({Color? borderColor}) {
    return BoxDecoration(
      color: slate900,
      borderRadius: BorderRadius.circular(cardRadius),
      border: Border.all(color: borderColor ?? slate800),
    );
  }

  static BoxDecoration emeraldGlow({double radius = cardRadius}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: emerald400.withValues(alpha: 0.25),
          blurRadius: 32,
          spreadRadius: 0,
        ),
      ],
    );
  }
}
