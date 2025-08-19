//widgets/color_utils.dart (hex ↔ Color helpers + palette)

import 'package:flutter/material.dart';

/// Convert hex string (#RRGGBB or #AARRGGBB) → Color
Color colorFromHex(String hex) {
  var h = hex.replaceAll('#', '');
  if (h.length == 6) h = 'FF$h'; // add alpha if missing
  return Color(int.parse(h, radix: 16));
}

/// Convert Color → hex string (#RRGGBB)
String hexFromColor(Color c) {
  // Use toARGB32() instead of .value (deprecated)
  final argb = c.toARGB32();
  final rgb = (argb & 0xFFFFFF); // strip alpha
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// Predefined color palette for categories
final List<Color> kColorChoices = [
  const Color(0xFF007BFF),
  const Color(0xFF28A745),
  const Color(0xFFFFC107),
  const Color(0xFFDC3545),
  const Color(0xFF17A2B8),
  const Color(0xFF6F42C1),
  const Color(0xFF6610F2),
  const Color(0xFF20C997),
  const Color(0xFFFD7E14),
  const Color(0xFF343A40),
];