import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/transaction.dart';
import '../services/tradeflow_api.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton.dart';
import '../widgets/status_badge.dart';
import 'create_transaction_screen.dart';
import 'escrow_screen.dart';

/// Écran d'historique complet des transactions de l'utilisateur connecté.
/// Filtre par statut : Tous / En cours / Terminées.
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Transaction> _allTransactions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final txs = await TradeFlowApi.instance.fetchTransactions();
      if (!mounted) return;
      setState(() { _allTransactions = txs; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<Transaction> get _active => _allTransactions
      .where((t) => [
        TransactionStatus.pending,
        TransactionStatus.inTransit,
        TransactionStatus.shipped,
        TransactionStatus.escrowConfirmed,
      ].contains(t.status))
      .toList();

  List<Transaction> get _completed => _allTransactions
      .where((t) => [
        TransactionStatus.delivered,
        TransactionStatus.disputed,
        TransactionStatus.releasing,
      ].contains(t.status))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Transactions'),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
          indicatorColor: navyBlue,
          labelColor: navyBlue,
          unselectedLabelColor: textTertiary,
          tabs: [
            Tab(text: 'Toutes (${_allTransactions.length})'),
            Tab(text: 'En cours (${_active.length})'),
            Tab(text: 'Terminées (${_completed.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const ListSkeleton(count: 5)
          : _error != null
              ? EmptyState(
                  icon: Icons.cloud_off,
                  title: 'Impossible de charger',
                  subtitle: 'Vérifiez votre connexion internet.',
                  buttonLabel: 'Réessayer',
                  buttonIcon: Icons.refresh,
                  onAction: _load,
                  secondaryButtonLabel: 'Contacter le support',
                  onSecondaryAction: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Support — bientôt disponible'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  ),
                  iconColor: danger,
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(_allTransactions),
                    _buildList(_active),
                    _buildList(_completed),
                  ],
                ),
    );
  }

  Widget _buildList(List<Transaction> items) {
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Aucune transaction',
        subtitle: 'Vos échanges commerciaux apparaîtront ici.',
        buttonLabel: 'Créer une transaction',
        buttonIcon: Icons.add,
        onAction: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateTransactionScreen(),
            ),
          );
          if (result == true && mounted) _load();
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: navyBlue,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _TransactionTile(
          transaction: items[i],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EscrowScreen(transaction: items[i]),
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;

  const _TransactionTile({required this.transaction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surfacePrimary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Row(
          children: [
            // Icône catégorie
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: paleBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_shipping_outlined, color: navyBlue, size: 22),
            ),
            const SizedBox(width: 12),
            // Détails
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.product,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.corridor,
                    style: AppText.caption(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(t.totalAmount / 1000).toStringAsFixed(0)} K FCFA',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: navyBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge(status: t.status),
                const SizedBox(height: 6),
                const Icon(Icons.chevron_right, color: textTertiary, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
