import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../theme/app_theme.dart';

class TrustScoreRing extends StatelessWidget {
  final int trustScore;
  final double radius;
  final double lineWidth;
  final Color progressColor;
  final Color backgroundColor;

  const TrustScoreRing({
    super.key,
    required this.trustScore,
    this.radius = 80,
    this.lineWidth = 12,
    this.progressColor = navyBlue,
    this.backgroundColor = paleBlue,
  });

  @override
  Widget build(BuildContext context) {
    return CircularPercentIndicator(
      radius: radius,
      lineWidth: lineWidth,
      animation: true,
      animationDuration: 1200,
      circularStrokeCap: CircularStrokeCap.round,
      percent: (trustScore / 100).clamp(0.0, 1.0),
      progressColor: progressColor,
      backgroundColor: backgroundColor,
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$trustScore',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: navyBlue,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '/100',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
