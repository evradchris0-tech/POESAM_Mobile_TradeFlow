import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// État vide réutilisable sur tous les écrans.
///
/// - Mode standard (par défaut) : centré, padding 40, icône 80×80.
/// - Mode [compact] : pour utilisation dans une liste/section, padding réduit.
/// - Actions optionnelles : bouton primaire (filled) + bouton secondaire
///   (text button), avec icônes optionnelles.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final IconData? buttonIcon;
  final VoidCallback? onAction;
  final String? secondaryButtonLabel;
  final VoidCallback? onSecondaryAction;
  final Color? iconColor;
  final bool compact;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.buttonIcon,
    this.onAction,
    this.secondaryButtonLabel,
    this.onSecondaryAction,
    this.iconColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final tint = iconColor ?? navyBlue;
    final pad = compact ? 20.0 : 40.0;
    final iconBox = compact ? 56.0 : 80.0;
    final iconSize = compact ? 26.0 : 36.0;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconBox,
              height: iconBox,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: iconSize, color: tint),
            ),
            SizedBox(height: compact ? 12 : 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: compact ? AppText.body(color: textPrimary, weight: FontWeight.w600) : AppText.h3(),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppText.caption(),
            ),
            if (buttonLabel != null && onAction != null) ...[
              SizedBox(height: compact ? 14 : 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: Icon(buttonIcon ?? Icons.add, size: 18),
                label: Text(buttonLabel!),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 16 : 20,
                    vertical: compact ? 10 : 12,
                  ),
                ),
              ),
            ],
            if (secondaryButtonLabel != null && onSecondaryAction != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onSecondaryAction,
                child: Text(
                  secondaryButtonLabel!,
                  style: AppText.caption(color: navyBlue, weight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
