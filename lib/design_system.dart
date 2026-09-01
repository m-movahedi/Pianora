import 'package:flutter/material.dart';

enum DesignLanguage { appleSoft, skeuomorphicInstrument, minimalSwiss }

Color readableForeground(Color background) {
  return readableForegroundFor([background]);
}

Color readableForegroundFor(Iterable<Color> backgrounds) {
  var minimumWhiteContrast = double.infinity;
  var minimumBlackContrast = double.infinity;
  for (final background in backgrounds) {
    final luminance = background.computeLuminance();
    final whiteContrast = 1.05 / (luminance + .05);
    final blackContrast = (luminance + .05) / .05;
    if (whiteContrast < minimumWhiteContrast) {
      minimumWhiteContrast = whiteContrast;
    }
    if (blackContrast < minimumBlackContrast) {
      minimumBlackContrast = blackContrast;
    }
  }
  return minimumWhiteContrast >= minimumBlackContrast
      ? Colors.white
      : const Color(0xFF111111);
}

class PianoraVisuals extends ThemeExtension<PianoraVisuals> {
  const PianoraVisuals({required this.language, required this.brightness});

  final DesignLanguage language;
  final Brightness brightness;

  bool get isSkeuomorphic => language == DesignLanguage.skeuomorphicInstrument;
  bool get isSwiss => language == DesignLanguage.minimalSwiss;
  bool get isDark => brightness == Brightness.dark;

  Color get wood => isDark ? const Color(0xFF3A2115) : const Color(0xFF6F3F27);
  Color get woodLight =>
      isDark ? const Color(0xFF573522) : const Color(0xFF9A6846);
  Color get ivory => isDark ? const Color(0xFF29251F) : const Color(0xFFFFF8E8);
  Color get lacquer =>
      isDark ? const Color(0xFF090909) : const Color(0xFF171513);
  Color get brass => isDark ? const Color(0xFFD5A94E) : const Color(0xFFB37A23);
  Color get felt => isDark ? const Color(0xFF6F1721) : const Color(0xFF8C2634);
  Color get swissPaper =>
      isDark ? const Color(0xFF111111) : const Color(0xFFF4F3EF);
  Color get swissSurface => isDark ? const Color(0xFF181818) : Colors.white;
  Color get swissInk =>
      isDark ? const Color(0xFFF5F4EF) : const Color(0xFF111111);

  @override
  PianoraVisuals copyWith({DesignLanguage? language, Brightness? brightness}) =>
      PianoraVisuals(
        language: language ?? this.language,
        brightness: brightness ?? this.brightness,
      );

  @override
  PianoraVisuals lerp(covariant PianoraVisuals? other, double t) {
    if (other == null || t < .5) return this;
    return other;
  }
}
