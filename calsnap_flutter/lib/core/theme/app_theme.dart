import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// CalSnap design system — faithful port of the web app tokens.
/// Dark-first: deep navy background + vibrant orange primary.
class AppColors {
  // Base
  static const background = Color(0xFF121523); // oklch(0.16 0.03 260)
  static const card = Color(0xFF1C2033); // oklch(0.21 0.035 260)
  static const secondary = Color(0xFF262B42); // oklch(0.27 0.04 260)
  static const muted = Color(0xFF212639); // oklch(0.24 0.035 260)
  static const foreground = Color(0xFFF8F9FC);
  static const mutedForeground = Color(0xFFA8ADC4); // oklch(0.72 0.02 260)

  // Brand
  static const primary = Color(0xFFF8823E); // oklch(0.72 0.19 42) vibrant orange
  static const primaryLight = Color(0xFFFDB44B); // oklch(0.80 0.17 65)
  static const primaryForeground = background;

  // Semantic
  static const success = Color(0xFF3DCC85); // oklch(0.72 0.18 152)
  static const warning = Color(0xFFF4C542); // oklch(0.82 0.17 85)
  static const destructive = Color(0xFFE85348); // oklch(0.65 0.22 27)
  static const info = Color(0xFF4A8CE8); // oklch(0.65 0.18 230)

  // Macros
  static const protein = Color(0xFFEF6B5A); // oklch(0.68 0.18 25)
  static const carbs = Color(0xFFE9B44C); // oklch(0.78 0.16 75)
  static const fat = Color(0xFF4FB8D8); // oklch(0.74 0.16 200)
  static const fiber = success;
  static const water = Color(0xFF54B9E8);

  // Lines
  static Color border = Colors.white.withValues(alpha: 0.08);
  static Color inputBorder = Colors.white.withValues(alpha: 0.12);

  // Gradients
  static const gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );
  static const gradientWarm = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFFE86A4A)],
  );
  static const gradientCool = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [info, success],
  );
}

class AppShadows {
  static List<BoxShadow> glow = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.5),
      blurRadius: 40,
      offset: const Offset(0, 10),
      spreadRadius: -10,
    ),
  ];
  static List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.5),
      blurRadius: 28,
      offset: const Offset(0, 8),
      spreadRadius: -14,
    ),
  ];
  static List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 10,
      offset: const Offset(0, 2),
      spreadRadius: -4,
    ),
  ];
}

class AppTheme {
  static ThemeData dark({required bool arabic}) {
    final baseText = arabic
        ? GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme)
        : GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme);

    final textTheme = baseText.apply(
      bodyColor: AppColors.foreground,
      displayColor: AppColors.foreground,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.background,
        primary: AppColors.primary,
        onPrimary: AppColors.primaryForeground,
        secondary: AppColors.secondary,
        error: AppColors.destructive,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
        iconTheme: const IconThemeData(color: AppColors.foreground),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryForeground,
          minimumSize: const Size.fromHeight(52),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.foreground,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: AppColors.inputBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.muted,
        hintStyle: const TextStyle(color: AppColors.mutedForeground),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF161A2B),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.mutedForeground,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.secondary,
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerColor: AppColors.border,
    );
  }
}

/// ── ACLEE Design Tokens ─────────────────────────────────
/// Single source of truth: spacing, radius, motion.
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const section = 28.0;
  static const page = 20.0;
}

class AppRadius {
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const pill = 999.0;
}

class AppMotion {
  static const fast = Duration(milliseconds: 160);
  static const base = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 420);
  static const entrance = Duration(milliseconds: 520);
  static const ring = Duration(milliseconds: 1100);
  static const easeOutExpo = Cubic(0.16, 1, 0.3, 1);
  static const easeOutBack = Cubic(0.34, 1.56, 0.64, 1);
  static const staggerStep = Duration(milliseconds: 70);
}
