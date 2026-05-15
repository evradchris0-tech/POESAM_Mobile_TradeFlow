import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final String role;
  final ValueChanged<int> onTap;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.role,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCustoms     = role == 'customs';
    final isTransporter = role == 'transporter';
    final bottomInset   = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      height: 72 + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Bar ─────────────────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: surfacePrimary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 32,
                    offset: const Offset(0, -8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Row(
                children: [
                  _NavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Accueil',
                    selected: currentIndex == 0,
                    onTap: () => _tap(0),
                  ),
                  _NavItem(
                    icon: isCustoms
                        ? Icons.policy_outlined
                        : isTransporter
                            ? Icons.local_shipping_outlined
                            : Icons.language_outlined,
                    activeIcon: isCustoms
                        ? Icons.policy
                        : isTransporter
                            ? Icons.local_shipping
                            : Icons.language,
                    label: isCustoms
                        ? 'Inspections'
                        : isTransporter
                            ? 'Cargaisons'
                            : 'Marché',
                    selected: currentIndex == 1,
                    onTap: () => _tap(1),
                  ),
                  const SizedBox(width: 76),
                  _NavItem(
                    icon: isCustoms
                        ? Icons.gavel_outlined
                        : Icons.swap_horiz_outlined,
                    activeIcon: isCustoms ? Icons.gavel : Icons.swap_horiz,
                    label: isCustoms
                        ? 'Litiges'
                        : isTransporter
                            ? 'Trajets'
                            : 'Échanges',
                    selected: currentIndex == 3,
                    onTap: () => _tap(3),
                  ),
                  _NavItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profil',
                    selected: currentIndex == 4,
                    onTap: () => _tap(4),
                  ),
                ],
              ),
            ),
          ),

          // ── Central FAB ─────────────────────────────────────────
          Positioned(
            top: -22,
            left: 0,
            right: 0,
            child: Center(
              child: _CentralFab(
                selected: currentIndex == 2,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onTap(2);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _tap(int index) {
    HapticFeedback.selectionClick();
    onTap(index);
  }
}

// ── Central FAB ────────────────────────────────────────────────────────────

class _CentralFab extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _CentralFab({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color baseColor  = selected ? navyBlue  : orange;
    final Color lightColor = selected
        ? mediumBlue
        : const Color(0xFFFF9F45);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Outer glow ring
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor.withValues(alpha: 0.18),
                lightColor.withValues(alpha: 0.08),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5),
            // Inner button
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [lightColor, baseColor],
                ),
                border: Border.all(color: surfacePrimary, width: 3.5),
                boxShadow: [
                  BoxShadow(
                    color: baseColor.withValues(alpha: 0.50),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: baseColor.withValues(alpha: 0.14),
                    blurRadius: 40,
                    spreadRadius: 8,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Specular shine
                      Positioned(
                        top: 7,
                        left: 9,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.28),
                          ),
                        ),
                      ),
                      Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) => ScaleTransition(
                            scale: anim,
                            child: child,
                          ),
                          child: Icon(
                            selected
                                ? Icons.auto_awesome
                                : Icons.auto_awesome_outlined,
                            key: ValueKey(selected),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? navyBlue : textTertiary,
            letterSpacing: selected ? 0.3 : 0,
          ),
          child: const Text('Guide IA'),
        ),
      ],
    );
  }
}

// ── Nav item ───────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: paleBlue.withValues(alpha: 0.5),
        highlightColor: paleBlue.withValues(alpha: 0.3),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pill with gradient fill when active
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFD9ECF8), paleBlue],
                        )
                      : const LinearGradient(
                          colors: [Colors.transparent, Colors.transparent],
                        ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AnimatedScale(
                  scale: selected ? 1.14 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: child,
                    ),
                    child: Icon(
                      selected ? activeIcon : icon,
                      key: ValueKey(selected),
                      color: selected ? navyBlue : textTertiary,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? navyBlue : textTertiary,
                  letterSpacing: selected ? 0.1 : 0,
                ),
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
