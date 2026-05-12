import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/transaction.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final TransactionStatus status;
  final EdgeInsetsGeometry padding;

  const StatusBadge({
    super.key,
    required this.status,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  ({Color bg, Color fg}) _colors() {
    switch (status) {
      case TransactionStatus.pending:
        return (bg: surfaceSecondary, fg: textTertiary);
      case TransactionStatus.escrowConfirmed:
        return (bg: const Color(0xFFE6F1FB), fg: const Color(0xFF185FA5));
      case TransactionStatus.shipped:
      case TransactionStatus.inTransit:
        return (bg: warningBg, fg: warningText);
      case TransactionStatus.delivered:
      case TransactionStatus.releasing:
        return (bg: successBg, fg: successText);
      case TransactionStatus.disputed:
        return (bg: dangerBg, fg: dangerText);
    }
  }

  static Color barColorOf(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return textTertiary;
      case TransactionStatus.escrowConfirmed:
        return mediumBlue;
      case TransactionStatus.shipped:
      case TransactionStatus.inTransit:
        return orange;
      case TransactionStatus.delivered:
      case TransactionStatus.releasing:
        return success;
      case TransactionStatus.disputed:
        return danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors();
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status.label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: c.fg,
        ),
      ),
    );
  }
}
