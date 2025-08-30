//widgets/icon_registry.dart (map icon names ↔ Material icons)

import 'package:flutter/material.dart';

final Map<String, IconData> iconRegistry = {
  'work': Icons.work,
  'laptop': Icons.laptop,
  'trending_up': Icons.trending_up,
  'restaurant': Icons.restaurant,
  'directions_bus': Icons.directions_bus,
  'shopping_cart': Icons.shopping_cart,
  'pets': Icons.pets,
  'home': Icons.home,
  'health_and_safety': Icons.health_and_safety,
  'school': Icons.school,
  'savings': Icons.savings,
  'entertainment': Icons.movie,
  'gift': Icons.card_giftcard,
  'travel': Icons.flight_takeoff,
};

/// Look up an IconData by its name string
IconData? iconFromName(String? name) =>
    name == null ? null : iconRegistry[name];

/// Look up the string name for an IconData
String? nameFromIcon(IconData? icon) {
  if (icon == null) return null;
  return iconRegistry.entries.firstWhere(
    (e) => e.value == icon,
    orElse: () => const MapEntry<String, IconData>('work', Icons.work),
  ).key;
}

