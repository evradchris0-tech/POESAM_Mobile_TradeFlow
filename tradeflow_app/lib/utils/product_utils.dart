import 'package:flutter/material.dart';

/// Retourne un [IconData] Material adapté au nom/emoji du produit.
/// Compatible avec les noms en français et les anciens champs emoji.
IconData productIconOf(String nameOrEmoji) {
  final n = nameOrEmoji.toLowerCase();
  if (n.contains('cacao') || n == '🍫') return Icons.eco_outlined;
  if (n.contains('café') || n.contains('cafe') || n == '☕') return Icons.local_cafe_outlined;
  if (n.contains('plantain') || n.contains('banane') || n == '🍌') return Icons.grass;
  if (n.contains('manioc') || n == '🌿') return Icons.spa_outlined;
  if (n.contains('huile') || n.contains('palme') || n == '🫙') return Icons.water_drop_outlined;
  if (n.contains('maïs') || n.contains('mais') || n == '🌽') return Icons.grain;
  if (n.contains('arachide') || n == '🥜') return Icons.scatter_plot_outlined;
  if (n.contains('gingembre') || n == '🫚') return Icons.spa_outlined;
  if (n.contains('bois') || n.contains('timber') || n.contains('lumber')) return Icons.forest_outlined;
  if (n.contains('coton') || n.contains('cotton')) return Icons.filter_vintage_outlined;
  if (n.contains('poisson') || n.contains('fish')) return Icons.set_meal_outlined;
  if (n.contains('sucre') || n.contains('sugar')) return Icons.science_outlined;
  if (n.contains('sésame') || n.contains('sesame')) return Icons.grain;
  if (n.contains('noix') || n.contains('cajou')) return Icons.eco_outlined;
  return Icons.inventory_2_outlined;
}

/// Couleur de catégorie associée au produit (pour l'icône de fond).
Color productColorOf(String name) {
  final n = name.toLowerCase();
  if (n.contains('cacao')) return const Color(0xFF5D4037);
  if (n.contains('café') || n.contains('cafe')) return const Color(0xFF4E342E);
  if (n.contains('plantain') || n.contains('banane')) return const Color(0xFF558B2F);
  if (n.contains('huile') || n.contains('palme')) return const Color(0xFFE65100);
  if (n.contains('maïs') || n.contains('mais')) return const Color(0xFFF57F17);
  if (n.contains('arachide')) return const Color(0xFF6D4C41);
  if (n.contains('gingembre') || n.contains('manioc')) return const Color(0xFF2E7D32);
  return const Color(0xFF1B4D8E); // navyBlue par défaut
}
