import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'theme/tokens.dart';
import 'theme/packs.dart';
import 'theme/build_theme.dart';

export 'theme/tokens.dart';
export 'theme/packs.dart';
export 'theme/build_theme.dart';

ThemeData gardenTheme(Brightness brightness) =>
    buildTheme(gardenPack, brightness);

abstract final class GardenMotion {
  static const duration = Duration(milliseconds: 260);
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
  GardenTokens get tokens =>
      Theme.of(this).extension<GardenTokens>() ??
      gardenPack.tokens(Theme.of(this).brightness);
  TextTheme get type => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
  bool get dark => Theme.of(this).brightness == Brightness.dark;
}
