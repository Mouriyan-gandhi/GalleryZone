import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand tokens ported from `frontend-web/app/globals.css` (Tailwind v4
/// CSS-first config — that file is the single source of truth, not this
/// comment). Dark is the product's hard default (`next-themes` with
/// `enableSystem: false`), light exists and must stay fully usable.
class AppColors {
  const AppColors._();

  static const darkBackground = Color(0xFF0B0A08);
  static const darkForeground = Color(0xFFF1ECE0);
  static const darkCard = Color(0xFF141209);
  static const darkSecondary = Color(0xFF1C1A12);
  static const darkMuted = Color(0xFF17150E);
  static const darkMutedForeground = Color(0xFF9C9686);
  static const darkGold = Color(0xFFC89A4A);
  static const darkGoldBright = Color(0xFFE9C57A);
  static const darkGoldDeep = Color(0xFF8A6423);
  static const darkBorder = Color(0xFF211F1B); // foreground ~10% over background

  static const lightBackground = Color(0xFFF7F3E9);
  static const lightForeground = Color(0xFF201C13);
  static const lightCard = Color(0xFFFDFBF5);
  static const lightSecondary = Color(0xFFEFEAD9);
  static const lightMuted = Color(0xFFF1ECDE);
  static const lightMutedForeground = Color(0xFF6B6656);
  static const lightGold = Color(0xFFA9782C);
  static const lightGoldBright = Color(0xFF8A6423);
  static const lightGoldDeep = Color(0xFF6E4F1B);
  static const lightBorder = Color(0xFFE3DDCE); // foreground ~12% over background

  static const destructive = Color(0xFFDC5B4A); // oklch(0.577 0.245 27.325), same both themes
}

/// Single proportional radius scale, base 12 — every other value is that
/// times a fixed multiplier (`globals.css` `--radius-*` tokens).
class AppRadius {
  const AppRadius._();

  static const double base = 12.0;
  static const double sm = base * 0.6; // 7.2
  static const double md = base * 0.8; // 9.6
  static const double lg = base; // 12
  static const double xl = base * 1.4; // 16.8
  static const double xl2 = base * 1.8; // 21.6
  static const double xl3 = base * 2.2; // 26.4
  static const double xl4 = base * 2.6; // 31.2 (full pill on badges/switches)
}

class AppTheme {
  const AppTheme._();

  static TextTheme _textTheme(Color foreground, Color muted) {
    final display = GoogleFonts.playfairDisplayTextTheme();
    final body = GoogleFonts.interTextTheme();
    return body
        .copyWith(
          displayLarge: display.displayLarge,
          displayMedium: display.displayMedium,
          displaySmall: display.displaySmall,
          headlineLarge: display.headlineLarge,
          headlineMedium: display.headlineMedium,
          headlineSmall: display.headlineSmall,
          titleLarge: display.titleLarge,
        )
        .apply(bodyColor: foreground, displayColor: foreground)
        .copyWith(bodySmall: body.bodySmall?.copyWith(color: muted));
  }

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      surface: AppColors.darkBackground,
      onSurface: AppColors.darkForeground,
      primary: AppColors.darkGold,
      onPrimary: AppColors.darkBackground,
      secondary: AppColors.darkSecondary,
      onSecondary: AppColors.darkForeground,
      error: AppColors.destructive,
      outline: AppColors.darkBorder,
    );
    return _build(scheme, AppColors.darkCard, AppColors.darkMuted, AppColors.darkForeground, AppColors.darkMutedForeground);
  }

  static ThemeData get light {
    const scheme = ColorScheme.light(
      surface: AppColors.lightBackground,
      onSurface: AppColors.lightForeground,
      primary: AppColors.lightGold,
      onPrimary: AppColors.lightCard,
      secondary: AppColors.lightSecondary,
      onSecondary: AppColors.lightForeground,
      error: AppColors.destructive,
      outline: AppColors.lightBorder,
    );
    return _build(scheme, AppColors.lightCard, AppColors.lightMuted, AppColors.lightForeground, AppColors.lightMutedForeground);
  }

  static ThemeData _build(ColorScheme scheme, Color card, Color muted, Color foreground, Color mutedForeground) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: _textTheme(foreground, mutedForeground),
      // Cards carry no border in the reference design — a subtle ring
      // (`ring-1 ring-foreground/10`) stands in for one, via a hairline
      // outline instead of elevation shadow.
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: scheme.outline, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: scheme.outline, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        ),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: scheme.primary,
        textColor: scheme.onPrimary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? scheme.onPrimary : muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? scheme.primary : muted,
        ),
      ),
    );
  }
}
