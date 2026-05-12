import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../data/mock_data.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/brand_logo.dart';
import '../widgets/metric_card.dart';
import '../widgets/skeleton.dart';
import '../widgets/transaction_card.dart';
import 'escrow_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;

  const HomeScreen({super.key, this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  int _unreadNotifs = 0;

  @override
  void initState() {
    super.initState();
    _unreadNotifs = mockNotifications.where((n) => n.unread).length;
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _unreadNotifs = mockNotifications.where((n) => n.unread).length;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Tableau de bord actualisé'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: navyBlue,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _openTransaction(Transaction tx) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EscrowScreen(transaction: tx)),
    );
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    if (!mounted) return;
    setState(() {
      _unreadNotifs = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = mockUser;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        leadingWidth: 56,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Center(child: BrandLogoIcon(size: 32)),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Bonjour, ${user.firstName} 👋',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            Text(
              user.company,
              style: GoogleFonts.inter(fontSize: 12, color: textTertiary),
            ),
          ],
        ),
        actions: [
          InkWell(
            onTap: () => widget.onNavigate?.call(4),
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: navyBlue,
                    child: Text(
                      user.initials,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: orange,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        'Pro',
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _openNotifications,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined,
                    color: textPrimary, size: 22),
                if (_unreadNotifs > 0)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      constraints:
                          const BoxConstraints(minWidth: 14, minHeight: 14),
                      decoration: BoxDecoration(
                        color: danger,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: appBarSurface, width: 1.5),
                      ),
                      child: Text(
                        '$_unreadNotifs',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const HomeSkeleton()
          : RefreshIndicator(
              color: navyBlue,
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _trustBanner(user.trustScore, user.trustLevel),
                    const SizedBox(height: 16),
                    _metricsGrid(),
                    const SizedBox(height: 24),
                    Text('Transactions en cours', style: AppText.h3()),
                    const SizedBox(height: 12),
                    ...mockTransactions.map(
                      (tx) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TransactionCard(
                          tx: tx,
                          onTap: () => _openTransaction(tx),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Opportunité du jour', style: AppText.h3()),
                    const SizedBox(height: 12),
                    _opportunityCard(),
                    const SizedBox(height: 16),
                    _alertCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _trustBanner(int score, String level) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [navyBlue, mediumBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trust Score',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$score/100',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    level,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          CircularPercentIndicator(
            radius: 38,
            lineWidth: 6,
            percent: score / 100,
            animation: true,
            animationDuration: 1200,
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: orange,
            backgroundColor: Colors.white.withOpacity(0.25),
            center: Text(
              '$score%',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: [
        MetricCard(
          value: formatCompactFCFA(1550000),
          label: 'Volume exporté',
          trend: '+12%',
          trendUp: true,
        ),
        const MetricCard(value: '3', label: 'Transactions actives'),
        const MetricCard(value: '84/100', label: 'Score moyen acheteurs'),
        MetricCard(value: formatFCFA(47250), label: 'Commissions économisées'),
      ],
    );
  }

  Widget _opportunityCard() {
    return Material(
      color: surfacePrimary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => widget.onNavigate?.call(1),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: surfacePrimary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: orange, width: 1),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🫙', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Huile de palme raffinée',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'CMR→GAB · Demande forte',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: successBg,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'Score 91',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: successText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '0% droits CEMAC · Marge estimée +18%',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => widget.onNavigate?.call(1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text("Voir l'acheteur"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _alertCard() {
    return Material(
      color: warningBg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _openTransaction(mockTransactions.first),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: warningBg,
            borderRadius: BorderRadius.circular(8),
            border: const Border(
              left: BorderSide(color: orange, width: 3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: orange, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Votre cargaison CMR→CIV arrive dans 3 jours. Confirmez la réception.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: warningText,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: warningText),
            ],
          ),
        ),
      ),
    );
  }
}
