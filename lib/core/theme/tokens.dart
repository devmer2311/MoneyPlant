import 'package:flutter/material.dart';

/// Semantic UI and illustration roles, shared by widgets and custom painters.
@immutable
class GardenTokens extends ThemeExtension<GardenTokens> {
  final Color launchTitleShadow;
  final Color hero;
  final Color onReceive;
  final Color receive;
  final Color owe;
  final Color danger;
  final Color plantShadow;
  final Color leafShadow;
  final Color leafHighlight;
  final Color leafMidtone;
  final Color leafShade;
  final Color potShade;
  final Color potHighlight;
  final Color potMidtone;
  final Color potEdge;
  final Color potRim;
  final Color soil;
  final Color sparkle;
  final Color expenseAccent;
  final Color heroMuted;
  final Color heroInk;
  final Color heroShadow;
  final Color heroDivider;
  final Color splitAccent;
  final Color goalAccent;
  final Color launchTrack;
  final Color launchGlow;
  final Color launchPetal;
  final Color launchLeafHighlight;
  final Color launchLeafMidtone;
  final Color launchStem;
  final Color launchLeafTip;
  final Color launchLeafShade;
  final Color launchLeafEdge;
  final Color launchPotHighlight;
  final Color launchPotShade;
  final Color launchPotRim;
  final Color launchSoil;
  final Color plantCheek;
  final Color coinEdge;
  final Color coinHighlight;
  final Color coinShade;
  final Color coinInk;
  final Color particlePetal;
  final Color particleLeaf;
  final Color loveSparkle;
  final Color entryAccent;
  final Color canvas;
  final Color surface;
  final Color surfaceAlt;
  final Color ink;
  final Color inkMuted;
  final Color brand;
  final Color onBrand;
  final Color onOwe;
  final Color warning;
  final Color success;
  final Color highlight;
  final Color shadow;
  final Color transparent;
  final Color translucentShadow;
  final String displayFont;
  final String bodyFont;
  final double radius;
  final Color selectedSurface;
  final Color navigation;
  final Color navigationInk;
  final Color savingSurface;
  final Color oweSurface;
  final Color launchCanvas;
  final Color headlineSide;
  final Color headingShadow;
  final Color chartTrack;
  final List<Color> chart;
  final List<Color> heroGradient;
  const GardenTokens({
    this.launchTitleShadow = const Color(0xFFCAD7B0),
    this.hero = const Color(0xFF173D31),
    this.onReceive = const Color(0xFF18251F),
    this.receive = const Color(0xFFDCF5A5),
    this.owe = const Color(0xFFE7DDF8),
    this.danger = const Color(0xFFAB302B),
    this.plantShadow = const Color(0xFF617856),
    this.leafShadow = const Color(0xFF254A24),
    this.leafHighlight = const Color(0xFFE3F7B4),
    this.leafMidtone = const Color(0xFF89B65A),
    this.leafShade = const Color(0xFF315E44),
    this.potShade = const Color(0xFFD4CAB5),
    this.potHighlight = const Color(0xFFFFFFF0),
    this.potMidtone = const Color(0xFFEDE4D2),
    this.potEdge = const Color(0xFFBCAF95),
    this.potRim = const Color(0xFFF9EDDC),
    this.soil = const Color(0xFF766F50),
    this.sparkle = const Color(0xFF70864D),
    this.expenseAccent = const Color(0xFFF6C2AE),
    this.heroMuted = const Color(0xFFCBD9CA),
    this.heroInk = const Color(0xFFF4F8EC),
    this.heroShadow = const Color(0xFF0F2A20),
    this.heroDivider = const Color(0xFF446050),
    this.splitAccent = const Color(0xFFBDDDEC),
    this.goalAccent = const Color(0xFFF3D99A),
    this.launchTrack = const Color(0xFFDDE5CD),
    this.launchGlow = const Color(0xFFC4DE97),
    this.launchPetal = const Color(0xFFDBD0F4),
    this.launchLeafHighlight = const Color(0xFFB4D283),
    this.launchLeafMidtone = const Color(0xFF659B59),
    this.launchStem = const Color(0xFF3C7044),
    this.launchLeafTip = const Color(0xFFCAE894),
    this.launchLeafShade = const Color(0xFF659A51),
    this.launchLeafEdge = const Color(0xFF78B560),
    this.launchPotHighlight = const Color(0xFFFFFCEE),
    this.launchPotShade = const Color(0xFFE1D4B9),
    this.launchPotRim = const Color(0xFFFFF8E8),
    this.launchSoil = const Color(0xFFAA9071),
    this.plantCheek = const Color(0xFFE9BBAF),
    this.coinEdge = const Color(0xFFB69C55),
    this.coinHighlight = const Color(0xFFFFEDAB),
    this.coinShade = const Color(0xFFD7BD72),
    this.coinInk = const Color(0xFF897438),
    this.particlePetal = const Color(0xFFC4ACE5),
    this.particleLeaf = const Color(0xFF9CBF64),
    this.loveSparkle = const Color(0xFF779C48),
    this.entryAccent = const Color(0xFFF4DAC6),
    this.canvas = const Color(0xFFF5F5EF),
    this.surface = Colors.white,
    this.surfaceAlt = const Color(0xFFF3F4EE),
    this.ink = const Color(0xFF18251F),
    this.inkMuted = const Color(0xFF555E57),
    this.brand = const Color(0xFF173D31),
    this.onBrand = Colors.white,
    this.onOwe = const Color(0xFF18251F),
    this.warning = const Color(0xFF805500),
    this.success = const Color(0xFF24633C),
    this.highlight = Colors.white,
    this.shadow = Colors.black,
    this.transparent = Colors.transparent,
    this.translucentShadow = const Color(0x44000000),
    this.displayFont = 'Outfit',
    this.bodyFont = 'Manrope',
    this.radius = 28,
    this.selectedSurface = const Color(0xFFDCF5A5),
    this.navigation = const Color(0xFFECF0DF),
    this.navigationInk = const Color(0xFF354538),
    this.savingSurface = const Color(0xFFEDF1DF),
    this.oweSurface = const Color(0xFFE7DDF8),
    this.launchCanvas = const Color(0xFFF6F7EA),
    this.headlineSide = const Color(0xFFB3C99D),
    this.headingShadow = const Color(0xFFDFE8D2),
    this.chartTrack = const Color(0xFFDCF5A5),
    this.chart = const [
      Color(0xFFF6C2AE),
      Color(0xFFDCF5A5),
      Color(0xFFE7DDF8),
      Color(0xFFBDDDEC),
      Color(0xFFF3D99A),
      Color(0xFF89B65A),
    ],
    this.heroGradient = const [Color(0xFF173D31), Color(0xFF0F2A20)],
  });
  @override
  GardenTokens copyWith({
    Color? launchTitleShadow,
    Color? hero,
    Color? onReceive,
    Color? receive,
    Color? owe,
    Color? danger,
    Color? plantShadow,
    Color? leafShadow,
    Color? leafHighlight,
    Color? leafMidtone,
    Color? leafShade,
    Color? potShade,
    Color? potHighlight,
    Color? potMidtone,
    Color? potEdge,
    Color? potRim,
    Color? soil,
    Color? sparkle,
    Color? expenseAccent,
    Color? heroMuted,
    Color? heroInk,
    Color? heroShadow,
    Color? heroDivider,
    Color? splitAccent,
    Color? goalAccent,
    Color? launchTrack,
    Color? launchGlow,
    Color? launchPetal,
    Color? launchLeafHighlight,
    Color? launchLeafMidtone,
    Color? launchStem,
    Color? launchLeafTip,
    Color? launchLeafShade,
    Color? launchLeafEdge,
    Color? launchPotHighlight,
    Color? launchPotShade,
    Color? launchPotRim,
    Color? launchSoil,
    Color? plantCheek,
    Color? coinEdge,
    Color? coinHighlight,
    Color? coinShade,
    Color? coinInk,
    Color? particlePetal,
    Color? particleLeaf,
    Color? loveSparkle,
    Color? entryAccent,
    Color? canvas,
    Color? surface,
    Color? surfaceAlt,
    Color? ink,
    Color? inkMuted,
    Color? brand,
    Color? onBrand,
    Color? onOwe,
    Color? warning,
    Color? success,
    Color? highlight,
    Color? shadow,
    Color? transparent,
    Color? translucentShadow,
    String? displayFont,
    String? bodyFont,
    double? radius,
    Color? selectedSurface,
    Color? navigation,
    Color? navigationInk,
    Color? savingSurface,
    Color? oweSurface,
    Color? launchCanvas,
    Color? headlineSide,
    Color? headingShadow,
    Color? chartTrack,
    List<Color>? chart,
    List<Color>? heroGradient,
  }) => GardenTokens(
    launchTitleShadow: launchTitleShadow ?? this.launchTitleShadow,
    hero: hero ?? this.hero,
    onReceive: onReceive ?? this.onReceive,
    receive: receive ?? this.receive,
    owe: owe ?? this.owe,
    danger: danger ?? this.danger,
    plantShadow: plantShadow ?? this.plantShadow,
    leafShadow: leafShadow ?? this.leafShadow,
    leafHighlight: leafHighlight ?? this.leafHighlight,
    leafMidtone: leafMidtone ?? this.leafMidtone,
    leafShade: leafShade ?? this.leafShade,
    potShade: potShade ?? this.potShade,
    potHighlight: potHighlight ?? this.potHighlight,
    potMidtone: potMidtone ?? this.potMidtone,
    potEdge: potEdge ?? this.potEdge,
    potRim: potRim ?? this.potRim,
    soil: soil ?? this.soil,
    sparkle: sparkle ?? this.sparkle,
    expenseAccent: expenseAccent ?? this.expenseAccent,
    heroMuted: heroMuted ?? this.heroMuted,
    heroInk: heroInk ?? this.heroInk,
    heroShadow: heroShadow ?? this.heroShadow,
    heroDivider: heroDivider ?? this.heroDivider,
    splitAccent: splitAccent ?? this.splitAccent,
    goalAccent: goalAccent ?? this.goalAccent,
    launchTrack: launchTrack ?? this.launchTrack,
    launchGlow: launchGlow ?? this.launchGlow,
    launchPetal: launchPetal ?? this.launchPetal,
    launchLeafHighlight: launchLeafHighlight ?? this.launchLeafHighlight,
    launchLeafMidtone: launchLeafMidtone ?? this.launchLeafMidtone,
    launchStem: launchStem ?? this.launchStem,
    launchLeafTip: launchLeafTip ?? this.launchLeafTip,
    launchLeafShade: launchLeafShade ?? this.launchLeafShade,
    launchLeafEdge: launchLeafEdge ?? this.launchLeafEdge,
    launchPotHighlight: launchPotHighlight ?? this.launchPotHighlight,
    launchPotShade: launchPotShade ?? this.launchPotShade,
    launchPotRim: launchPotRim ?? this.launchPotRim,
    launchSoil: launchSoil ?? this.launchSoil,
    plantCheek: plantCheek ?? this.plantCheek,
    coinEdge: coinEdge ?? this.coinEdge,
    coinHighlight: coinHighlight ?? this.coinHighlight,
    coinShade: coinShade ?? this.coinShade,
    coinInk: coinInk ?? this.coinInk,
    particlePetal: particlePetal ?? this.particlePetal,
    particleLeaf: particleLeaf ?? this.particleLeaf,
    loveSparkle: loveSparkle ?? this.loveSparkle,
    entryAccent: entryAccent ?? this.entryAccent,
    canvas: canvas ?? this.canvas,
    surface: surface ?? this.surface,
    surfaceAlt: surfaceAlt ?? this.surfaceAlt,
    ink: ink ?? this.ink,
    inkMuted: inkMuted ?? this.inkMuted,
    brand: brand ?? this.brand,
    onBrand: onBrand ?? this.onBrand,
    onOwe: onOwe ?? this.onOwe,
    warning: warning ?? this.warning,
    success: success ?? this.success,
    highlight: highlight ?? this.highlight,
    shadow: shadow ?? this.shadow,
    transparent: transparent ?? this.transparent,
    translucentShadow: translucentShadow ?? this.translucentShadow,
    displayFont: displayFont ?? this.displayFont,
    bodyFont: bodyFont ?? this.bodyFont,
    radius: radius ?? this.radius,
    selectedSurface: selectedSurface ?? this.selectedSurface,
    navigation: navigation ?? this.navigation,
    navigationInk: navigationInk ?? this.navigationInk,
    savingSurface: savingSurface ?? this.savingSurface,
    oweSurface: oweSurface ?? this.oweSurface,
    launchCanvas: launchCanvas ?? this.launchCanvas,
    headlineSide: headlineSide ?? this.headlineSide,
    headingShadow: headingShadow ?? this.headingShadow,
    chartTrack: chartTrack ?? this.chartTrack,
    chart: chart ?? this.chart,
    heroGradient: heroGradient ?? this.heroGradient,
  );
  @override
  GardenTokens lerp(covariant GardenTokens? other, double t) {
    if (other == null) return this;
    return GardenTokens(
      launchTitleShadow: Color.lerp(
        launchTitleShadow,
        other.launchTitleShadow,
        t,
      )!,
      hero: Color.lerp(hero, other.hero, t)!,
      onReceive: Color.lerp(onReceive, other.onReceive, t)!,
      receive: Color.lerp(receive, other.receive, t)!,
      owe: Color.lerp(owe, other.owe, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      plantShadow: Color.lerp(plantShadow, other.plantShadow, t)!,
      leafShadow: Color.lerp(leafShadow, other.leafShadow, t)!,
      leafHighlight: Color.lerp(leafHighlight, other.leafHighlight, t)!,
      leafMidtone: Color.lerp(leafMidtone, other.leafMidtone, t)!,
      leafShade: Color.lerp(leafShade, other.leafShade, t)!,
      potShade: Color.lerp(potShade, other.potShade, t)!,
      potHighlight: Color.lerp(potHighlight, other.potHighlight, t)!,
      potMidtone: Color.lerp(potMidtone, other.potMidtone, t)!,
      potEdge: Color.lerp(potEdge, other.potEdge, t)!,
      potRim: Color.lerp(potRim, other.potRim, t)!,
      soil: Color.lerp(soil, other.soil, t)!,
      sparkle: Color.lerp(sparkle, other.sparkle, t)!,
      expenseAccent: Color.lerp(expenseAccent, other.expenseAccent, t)!,
      heroMuted: Color.lerp(heroMuted, other.heroMuted, t)!,
      heroInk: Color.lerp(heroInk, other.heroInk, t)!,
      heroShadow: Color.lerp(heroShadow, other.heroShadow, t)!,
      heroDivider: Color.lerp(heroDivider, other.heroDivider, t)!,
      splitAccent: Color.lerp(splitAccent, other.splitAccent, t)!,
      goalAccent: Color.lerp(goalAccent, other.goalAccent, t)!,
      launchTrack: Color.lerp(launchTrack, other.launchTrack, t)!,
      launchGlow: Color.lerp(launchGlow, other.launchGlow, t)!,
      launchPetal: Color.lerp(launchPetal, other.launchPetal, t)!,
      launchLeafHighlight: Color.lerp(
        launchLeafHighlight,
        other.launchLeafHighlight,
        t,
      )!,
      launchLeafMidtone: Color.lerp(
        launchLeafMidtone,
        other.launchLeafMidtone,
        t,
      )!,
      launchStem: Color.lerp(launchStem, other.launchStem, t)!,
      launchLeafTip: Color.lerp(launchLeafTip, other.launchLeafTip, t)!,
      launchLeafShade: Color.lerp(launchLeafShade, other.launchLeafShade, t)!,
      launchLeafEdge: Color.lerp(launchLeafEdge, other.launchLeafEdge, t)!,
      launchPotHighlight: Color.lerp(
        launchPotHighlight,
        other.launchPotHighlight,
        t,
      )!,
      launchPotShade: Color.lerp(launchPotShade, other.launchPotShade, t)!,
      launchPotRim: Color.lerp(launchPotRim, other.launchPotRim, t)!,
      launchSoil: Color.lerp(launchSoil, other.launchSoil, t)!,
      plantCheek: Color.lerp(plantCheek, other.plantCheek, t)!,
      coinEdge: Color.lerp(coinEdge, other.coinEdge, t)!,
      coinHighlight: Color.lerp(coinHighlight, other.coinHighlight, t)!,
      coinShade: Color.lerp(coinShade, other.coinShade, t)!,
      coinInk: Color.lerp(coinInk, other.coinInk, t)!,
      particlePetal: Color.lerp(particlePetal, other.particlePetal, t)!,
      particleLeaf: Color.lerp(particleLeaf, other.particleLeaf, t)!,
      loveSparkle: Color.lerp(loveSparkle, other.loveSparkle, t)!,
      entryAccent: Color.lerp(entryAccent, other.entryAccent, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      onOwe: Color.lerp(onOwe, other.onOwe, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      success: Color.lerp(success, other.success, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      transparent: Color.lerp(transparent, other.transparent, t)!,
      translucentShadow: Color.lerp(
        translucentShadow,
        other.translucentShadow,
        t,
      )!,
      displayFont: t < .5 ? displayFont : other.displayFont,
      bodyFont: t < .5 ? bodyFont : other.bodyFont,
      radius: radius + (other.radius - radius) * t,
      selectedSurface: Color.lerp(selectedSurface, other.selectedSurface, t)!,
      navigation: Color.lerp(navigation, other.navigation, t)!,
      navigationInk: Color.lerp(navigationInk, other.navigationInk, t)!,
      savingSurface: Color.lerp(savingSurface, other.savingSurface, t)!,
      oweSurface: Color.lerp(oweSurface, other.oweSurface, t)!,
      launchCanvas: Color.lerp(launchCanvas, other.launchCanvas, t)!,
      headlineSide: Color.lerp(headlineSide, other.headlineSide, t)!,
      headingShadow: Color.lerp(headingShadow, other.headingShadow, t)!,
      chartTrack: Color.lerp(chartTrack, other.chartTrack, t)!,
      chart: List.generate(
        chart.length,
        (i) => Color.lerp(chart[i], other.chart[i], t)!,
      ),
      heroGradient: List.generate(
        heroGradient.length,
        (i) => Color.lerp(heroGradient[i], other.heroGradient[i], t)!,
      ),
    );
  }
}
