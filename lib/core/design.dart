import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

abstract final class Palette {
  static const forest = Color(0xFF173D31);
  static const ink = Color(0xFF18251F);
  static const lime = Color(0xFFDCF5A5);
  static const lilac = Color(0xFFE7DDF8);
  static const coral = Color(0xFFCA6557);
  static const radius = 28.0;
  static const gap = 20.0;
  static const motion = Duration(milliseconds: 260);
  static const curve = Curves.easeOutCubic;
}

ThemeData gardenTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: Palette.forest,
    brightness: brightness,
    primary: dark ? Palette.lime : Palette.forest,
    surface: dark ? const Color(0xFF1D2A24) : Colors.white,
    onSurface: dark ? const Color(0xFFF1F3EC) : Palette.ink,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark
        ? const Color(0xFF111C17)
        : const Color(0xFFF5F5EF),
    fontFamily: 'Manrope',
    fontFamilyFallback: const ['NotoSans', 'Outfit'],
  );
  return base.copyWith(
    textTheme: base.textTheme
        .copyWith(
          displayLarge: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 64,
            height: 1.05,
            letterSpacing: -2.5,
            fontWeight: FontWeight.w500,
            color: scheme.onSurface,
          ),
          displaySmall: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 40,
            height: 1.12,
            letterSpacing: -1.4,
            fontWeight: FontWeight.w500,
            color: scheme.onSurface,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 28,
            letterSpacing: -.6,
            fontWeight: FontWeight.w500,
            color: scheme.onSurface,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 22,
            letterSpacing: -.4,
            fontWeight: FontWeight.w500,
            color: scheme.onSurface,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            height: 1.6,
            color: scheme.onSurface,
          ),
          labelSmall: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 10,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w700,
            color: scheme.onSurfaceVariant,
          ),
        )
        .apply(fontFamilyFallback: const ['NotoSans', 'Outfit']),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF25372E) : const Color(0xFFF3F4EE),
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
      color: scheme.onSurface.withValues(alpha: .08),
      space: 28,
    ),
  );
}

String money(int minor, [String currency = 'INR', bool compact = false]) =>
    NumberFormat.currency(
      locale: 'en_IN',
      symbol: currency == 'INR'
          ? '₹'
          : currency == 'USD'
          ? '\$'
          : '€',
      decimalDigits: compact && minor % 100 == 0 ? 0 : 2,
    ).format(minor / 100);

extension GardenContext on BuildContext {
  TextTheme get type => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
  bool get dark => Theme.of(this).brightness == Brightness.dark;
}
