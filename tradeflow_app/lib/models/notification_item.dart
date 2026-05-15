import 'package:flutter/material.dart';

enum NotificationKind { transit, escrow, opportunity, doc, system }

class NotificationItem {
  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final String timeAgo;
  final bool unread;

  const NotificationItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.timeAgo,
    this.unread = true,
  });
}

extension NotificationKindUi on NotificationKind {
  IconData get icon {
    switch (this) {
      case NotificationKind.transit:
        return Icons.local_shipping_outlined;
      case NotificationKind.escrow:
        return Icons.lock_outline;
      case NotificationKind.opportunity:
        return Icons.trending_up;
      case NotificationKind.doc:
        return Icons.description_outlined;
      case NotificationKind.system:
        return Icons.notifications_outlined;
    }
  }
}
