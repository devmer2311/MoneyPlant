import 'package:flutter/material.dart';

import 'tokens.dart';

double contrastRatio(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return ((x > y ? x : y) + .05) / ((x > y ? y : x) + .05);
}

/// Keep the icon legible across every stop, not just the tile's base tint.
class DepthShades {
  final List<Color> stops;
  final Color foreground;
  const DepthShades(this.stops, this.foreground);

  factory DepthShades.forTint(Color tint, GardenTokens tokens) {
    final stops = [
      Color.lerp(tint, tokens.highlight, .16)!,
      tint,
      Color.lerp(tint, tokens.shadow, .05)!,
    ];
    for (final foreground in [tokens.hero, tokens.highlight, tokens.shadow]) {
      if (stops.every((color) => contrastRatio(color, foreground) >= 4.5)) {
        return DepthShades(stops, foreground);
      }
    }
    final foreground =
        contrastRatio(tint, tokens.highlight) >
            contrastRatio(tint, tokens.shadow)
        ? tokens.highlight
        : tokens.shadow;
    return DepthShades([tint, tint, tint], foreground);
  }
}
