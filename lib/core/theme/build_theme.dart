import 'package:flutter/material.dart';

import 'packs.dart';

ThemeData buildTheme(ThemePack pack, Brightness brightness) {
  final tokens = pack.tokens(brightness);
  final scheme = ColorScheme.fromSeed(
    seedColor: tokens.hero,
    brightness: brightness,
    primary: tokens.brand,
    onPrimary: tokens.onBrand,
    primaryContainer: tokens.selectedSurface,
    onPrimaryContainer: tokens.ink,
    secondary: tokens.receive,
    onSecondary: tokens.onReceive,
    secondaryContainer: tokens.selectedSurface,
    onSecondaryContainer: tokens.ink,
    tertiary: tokens.owe,
    onTertiary: tokens.onOwe,
    tertiaryContainer: tokens.oweSurface,
    onTertiaryContainer: tokens.ink,
    surfaceContainerHighest: tokens.surfaceAlt,
    outline: tokens.inkMuted,
    onSurfaceVariant: tokens.inkMuted,
    surface: tokens.surface,
    onSurface: tokens.ink,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: tokens.canvas,
    fontFamily: tokens.bodyFont,
    extensions: [tokens],
    fontFamilyFallback: const ['NotoSans', 'Outfit'],
  );
  return base.copyWith(
    textTheme: base.textTheme
        .copyWith(
          displayLarge: TextStyle(
            fontFamily: tokens.displayFont,
            fontSize: 64,
            height: 1.05,
            letterSpacing: -2.5,
            fontWeight: FontWeight.w500,
            color: scheme.onSurface,
          ),
          displaySmall: TextStyle(
            fontFamily: tokens.displayFont,
            fontSize: 40,
            height: 1.12,
            letterSpacing: -1.4,
            fontWeight: FontWeight.w500,
            color: scheme.onSurface,
          ),
          headlineMedium: TextStyle(
            fontFamily: tokens.displayFont,
            fontSize: 28,
            letterSpacing: -.6,
            fontWeight: FontWeight.w500,
            color: scheme.onSurface,
          ),
          titleLarge: TextStyle(
            fontFamily: tokens.displayFont,
            fontSize: 22,
            letterSpacing: -.4,
            fontWeight: FontWeight.w500,
            color: scheme.onSurface,
          ),
          titleMedium: TextStyle(
            fontFamily: tokens.bodyFont,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
          bodyMedium: TextStyle(
            fontFamily: tokens.bodyFont,
            fontSize: 13,
            height: 1.6,
            color: scheme.onSurface,
          ),
          labelSmall: TextStyle(
            fontFamily: tokens.bodyFont,
            fontSize: 10,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w700,
            color: scheme.onSurfaceVariant,
          ),
        )
        .apply(fontFamilyFallback: const ['NotoSans', 'Outfit']),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tokens.surfaceAlt,
      contentPadding: const EdgeInsets.all(18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 94),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.onSurface.withValues(alpha: .18),
      space: 28,
    ),
  );
}
