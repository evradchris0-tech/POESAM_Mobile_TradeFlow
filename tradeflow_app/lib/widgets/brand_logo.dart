import 'package:flutter/material.dart';

/// Logo TradeFlow Africa — version "icône" carrée.
/// Le PNG complet est large (icône Afrique + texte). On affiche uniquement
/// la partie gauche (l'icône) via un clip carré + alignement à gauche.
class BrandLogoIcon extends StatelessWidget {
  final double size;
  final Color? background;
  final double radius;

  const BrandLogoIcon({
    super.key,
    this.size = 32,
    this.background,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/logo.png',
        fit: BoxFit.fitHeight,
        alignment: Alignment.centerLeft,
      ),
    );
  }
}

/// Logo TradeFlow Africa — version "full" (icône + texte) sur fond clair.
class BrandLogoFull extends StatelessWidget {
  final double height;

  const BrandLogoFull({super.key, this.height = 40});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo.png',
      height: height,
      fit: BoxFit.contain,
    );
  }
}
