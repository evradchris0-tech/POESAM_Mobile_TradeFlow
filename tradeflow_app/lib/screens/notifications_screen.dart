import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/notification_item.dart';
import '../services/tradeflow_api.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem>? _items;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await TradeFlowApi.instance.fetchNotifications();
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _markAllRead() {
    if (_items == null) return;
    setState(() {
      _items = _items!
          .map((n) => NotificationItem(
                id: n.id,
                kind: n.kind,
                title: n.title,
                body: n.body,
                timeAgo: n.timeAgo,
                unread: false,
              ))
          .toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Toutes les notifications marquées comme lues'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: navyBlue,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _markRead(int i) {
    if (_items == null) return;
    setState(() {
      _items![i] = NotificationItem(
        id: _items![i].id,
        kind: _items![i].kind,
        title: _items![i].title,
        body: _items![i].body,
        timeAgo: _items![i].timeAgo,
        unread: false,
      );
    });
  }

  ({Color bg, Color fg}) _iconColors(NotificationKind k) {
    switch (k) {
      case NotificationKind.transit:
        return (bg: warningBg, fg: warningText);
      case NotificationKind.escrow:
        return (bg: successBg, fg: successText);
      case NotificationKind.opportunity:
        return (bg: paleBlue, fg: navyBlue);
      case NotificationKind.doc:
        return (bg: docBg, fg: docText);
      case NotificationKind.system:
        return (bg: surfaceSecondary, fg: textSecondary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _items?.where((n) => n.unread).length ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Tout lire',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: navyBlue,
                ),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const ListSkeleton(count: 6)
          : (_items == null || _items!.isEmpty)
              ? const EmptyState(
                  compact: true,
                  icon: Icons.notifications_off_outlined,
                  title: 'Aucune notification',
                  subtitle: 'Vous serez notifié des mises à jour de vos transactions ici.',
                )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _items!.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 72, endIndent: 16),
              itemBuilder: (_, i) {
                final n = _items![i];
                final c = _iconColors(n.kind);
                return InkWell(
                  onTap: () => _markRead(i),
                  child: Container(
                    color: n.unread ? paleBlue.withValues(alpha: 0.25) : null,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: c.bg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(n.kind.icon, size: 20, color: c.fg),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      n.title,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: n.unread
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (n.unread)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(left: 6, top: 4),
                                      decoration: const BoxDecoration(
                                        color: danger,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                n.body,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: textSecondary,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                n.timeAgo,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
