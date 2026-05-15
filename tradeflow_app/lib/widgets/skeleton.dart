import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class Skeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const Skeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 6,
  });

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(skeletonBase, skeletonHighlight, _ctrl.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

class SkeletonBlock extends StatelessWidget {
  final double height;
  final double radius;

  const SkeletonBlock({
    super.key,
    this.height = 80,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Skeleton(width: double.infinity, height: height, radius: radius);
  }
}

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        const SkeletonBlock(height: 110),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.7,
          children: const [
            SkeletonBlock(height: 70, radius: 8),
            SkeletonBlock(height: 70, radius: 8),
            SkeletonBlock(height: 70, radius: 8),
            SkeletonBlock(height: 70, radius: 8),
          ],
        ),
        const SizedBox(height: 24),
        const Skeleton(width: 180, height: 16),
        const SizedBox(height: 12),
        for (int i = 0; i < 3; i++) ...[
          const SkeletonBlock(height: 90),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        const Skeleton(width: 160, height: 16),
        const SizedBox(height: 12),
        const SkeletonBlock(height: 130),
      ],
    );
  }
}

class ListSkeleton extends StatelessWidget {
  final int count;
  final double itemHeight;

  const ListSkeleton({super.key, this.count = 4, this.itemHeight = 84});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => SkeletonBlock(height: itemHeight),
    );
  }
}

/// Skeleton pour ProfileScreen — même style que HomeSkeleton.
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: const [
        // Header avatar + nom
        SkeletonBlock(height: 120, radius: 16),
        SizedBox(height: 16),
        // Trust Score banner
        SkeletonBlock(height: 100),
        SizedBox(height: 16),
        // Métriques (4 cases)
        SkeletonBlock(height: 76, radius: 10),
        SizedBox(height: 12),
        SkeletonBlock(height: 76, radius: 10),
        SizedBox(height: 24),
        // Section KYC
        Skeleton(width: 140, height: 14),
        SizedBox(height: 12),
        SkeletonBlock(height: 56, radius: 8),
        SizedBox(height: 8),
        SkeletonBlock(height: 56, radius: 8),
        SizedBox(height: 8),
        SkeletonBlock(height: 56, radius: 8),
        SizedBox(height: 24),
        // Section corridors
        Skeleton(width: 120, height: 14),
        SizedBox(height: 12),
        SkeletonBlock(height: 44, radius: 8),
      ],
    );
  }
}

