import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../config/demo_config.dart';
import '../data/mock_data.dart';
import '../models/transaction.dart';
import '../models/user_profile.dart';
import '../services/tradeflow_api.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/brand_logo.dart';
import '../widgets/empty_state.dart';
import '../widgets/metric_card.dart';
import '../widgets/skeleton.dart';
import '../widgets/transaction_card.dart';
import 'create_transaction_screen.dart';
import 'escrow_screen.dart';
import 'notifications_screen.dart';
import 'transaction_history_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;

  const HomeScreen({super.key, this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  bool _slowNetwork = false;
  int _unreadNotifs = 0;

  UserProfile? _user;
  List<Transaction> _transactions = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    try {
      final results = await Future.wait([
        TradeFlowApi.instance.fetchUserProfile(),
        TradeFlowApi.instance.fetchTransactions(),
        TradeFlowApi.instance.fetchNotifications(),
      ]);
      if (!mounted) return;
      setState(() {
        _user = results[0] as UserProfile;
        _transactions = results[1] as List<Transaction>;
        final notifs = results[2] as List;
        _unreadNotifs = notifs.where((n) => n.unread == true).length;
        _error = null;
        _loading = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _slowNetwork = true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    try {
      final results = await Future.wait([
        TradeFlowApi.instance.fetchUserProfile(),
        TradeFlowApi.instance.fetchTransactions(),
        TradeFlowApi.instance.fetchNotifications(),
      ]);
      if (!mounted) return;
      setState(() {
        _user = results[0] as UserProfile;
        _transactions = results[1] as List<Transaction>;
        final notifs = results[2] as List;
        _unreadNotifs = notifs.where((n) => n.unread == true).length;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    }
    if (!mounted) return;
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
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('TradeFlow')),
        body: const ListSkeleton(count: 4),
      );
    }

    if (_slowNetwork && _user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('TradeFlow')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.signal_wifi_statusbar_connected_no_internet_4,
                    size: 48, color: warning),
                const SizedBox(height: 12),
                Text('Réseau lent ou indisponible', style: AppText.h3()),
                const SizedBox(height: 8),
                Text(
                  'La connexion a expiré. Activez le mode démo pour continuer avec des données simulées.',
                  textAlign: TextAlign.center,
                  style: AppText.caption(),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    DemoConfig.kUseMockFallback = true;
                    setState(() => _slowNetwork = false);
                    _initialLoad();
                  },
                  icon: const Icon(Icons.science_outlined, size: 18),
                  label: const Text('Activer le mode démo'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() => _slowNetwork = false);
                    _initialLoad();
                  },
                  child: Text('Réessayer', style: AppText.body(color: navyBlue)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null || (!DemoConfig.kUseMockFallback && _user == null)) {
      return Scaffold(
        appBar: AppBar(title: const Text('TradeFlow')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: danger),
                const SizedBox(height: 12),
                Text('Impossible de charger les données', style: AppText.h3()),
                const SizedBox(height: 8),
                Text(_error ?? 'Connexion perdue',
                    textAlign: TextAlign.center, style: AppText.caption()),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refresh,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final user = _user ?? mockUser;

    return Scaffold(
      body: RefreshIndicator(
        color: navyBlue,
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(user),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _metricsGrid(),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          user.role == 'customs'
                              ? 'Dossiers à inspecter'
                              : (user.role == 'transporter'
                                  ? 'Livraisons actives'
                                  : 'Transactions en cours'),
                          style: AppText.h3(),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TransactionHistoryScreen(),
                            ),
                          ),
                          child: Text(
                            'Voir tout',
                            style: AppText.caption(
                                color: navyBlue, weight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_transactions.isEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: surfacePrimary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: 0.5),
                        ),
                        child: EmptyState(
                          compact: true,
                          icon: user.role == 'customs'
                              ? Icons.policy_outlined
                              : Icons.receipt_long_outlined,
                          title: user.role == 'customs'
                              ? 'Aucun dossier en attente'
                              : 'Aucune transaction active',
                          subtitle: user.role == 'customs'
                              ? 'Toutes les déclarations sont traitées.'
                              : 'Vos échanges en cours apparaîtront ici.',
                          buttonLabel:
                              user.role == 'pme' ? 'Créer une transaction' : null,
                          buttonIcon: Icons.add,
                          onAction: user.role == 'pme'
                              ? () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const CreateTransactionScreen(),
                                    ),
                                  );
                                  if (result == true) _refresh();
                                }
                              : null,
                        ),
                      )
                    else
                      ..._transactions.map(
                        (tx) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TransactionCard(
                            tx: tx,
                            onTap: () => _openTransaction(tx),
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    if (user.role == 'pme' || user.role == 'buyer') ...[
                      Text('Opportunité du jour', style: AppText.h3()),
                      const SizedBox(height: 12),
                      _opportunityCard(),
                      const SizedBox(height: 16),
                    ],
                    if (user.role == 'customs' ||
                        user.role == 'transporter') ...[
                      Text('Alertes système', style: AppText.h3()),
                      const SizedBox(height: 12),
                      _alertCard(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateTransactionScreen()),
          );
          if (result == true) {
            _refresh();
          }
        },
        backgroundColor: navyBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Créer',
            style: AppText.body(color: Colors.white, weight: FontWeight.bold)),
      ),
    );
  }

  // ── Hero header ─────────────────────────────────────────────────────────────

  Widget _buildHero(UserProfile user) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D2444), navyBlue, mediumBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.50, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _HomeGeometry())),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar: logo + avatar + bell
                  Row(
                    children: [
                      const ColorFiltered(
                        colorFilter: ColorFilter.mode(
                            Colors.white, BlendMode.srcIn),
                        child: BrandLogoFull(height: 24),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => widget.onNavigate?.call(4),
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: 17,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.2),
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
                                    border: Border.all(
                                        color: const Color(0xFF0D2444),
                                        width: 1.5),
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
                      const SizedBox(width: 4),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            onPressed: _openNotifications,
                            icon: const Icon(Icons.notifications_outlined,
                                color: Colors.white, size: 22),
                          ),
                          if (_unreadNotifs > 0)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                constraints: const BoxConstraints(
                                    minWidth: 14, minHeight: 14),
                                decoration: BoxDecoration(
                                  color: danger,
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                      color: navyBlue, width: 1.5),
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
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Greeting + trust score
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bonjour,',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Text(
                              user.firstName,
                              style: GoogleFonts.inter(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              user.company,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                      CircularPercentIndicator(
                        radius: 40,
                        lineWidth: 5.5,
                        percent: (user.trustScore / 100).clamp(0.0, 1.0),
                        animation: true,
                        animationDuration: 1200,
                        circularStrokeCap: CircularStrokeCap.round,
                        progressColor: orange,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        center: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${user.trustScore}',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                            Text(
                              '/100',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Badges row
                  Row(
                    children: [
                      _GlassPill(user.trustLevel),
                      const SizedBox(width: 8),
                      const _GlassPill('PAPSS · CEMAC'),
                      const SizedBox(width: 8),
                      const _GlassPill('7 pays'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricsGrid() {
    final user = _user ?? mockUser;
    final r = user.role;

    if (r == 'customs') {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.7,
        children: const [
          MetricCard(
              value: '142',
              label: 'Dossiers traités',
              trend: '+5%',
              trendUp: true,
              icon: Icons.folder_open),
          MetricCard(
              value: '3',
              label: 'Inspections en cours',
              icon: Icons.search),
          MetricCard(
              value: '12',
              label: 'Alertes fraude',
              trend: '-2',
              trendUp: true,
              icon: Icons.warning_amber_rounded),
          MetricCard(
              value: '1h20',
              label: 'Temps moyen de traitement',
              icon: Icons.timer_outlined),
        ],
      );
    } else if (r == 'transporter') {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.7,
        children: const [
          MetricCard(
              value: '45',
              label: 'Trajets complétés',
              trend: '+12%',
              trendUp: true,
              icon: Icons.route),
          MetricCard(
              value: '4',
              label: 'Cargaisons en transit',
              icon: Icons.local_shipping_outlined),
          MetricCard(
              value: '98%',
              label: 'Taux de livraison à l\'heure',
              icon: Icons.check_circle_outline),
          MetricCard(
              value: '2.4T',
              label: 'Volume transporté (Mois)',
              icon: Icons.scale_outlined),
        ],
      );
    } else if (r == 'buyer') {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.7,
        children: [
          MetricCard(
              value: formatCompactFCFA(3200000),
              label: 'Dépenses totales',
              trend: '+8%',
              trendUp: false,
              icon: Icons.account_balance_wallet_outlined),
          const MetricCard(
              value: '5',
              label: 'Commandes actives',
              icon: Icons.shopping_cart_checkout),
          const MetricCard(
              value: '92/100',
              label: 'Score moyen fournisseurs',
              icon: Icons.star_border),
          MetricCard(
              value: formatFCFA(120000),
              label: 'Économies logistiques',
              icon: Icons.savings_outlined),
        ],
      );
    }

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
          icon: Icons.trending_up,
        ),
        const MetricCard(
            value: '3',
            label: 'Transactions actives',
            icon: Icons.sync_alt),
        const MetricCard(
            value: '84/100',
            label: 'Score moyen acheteurs',
            icon: Icons.star_border),
        MetricCard(
            value: formatFCFA(47250),
            label: 'Commissions économisées',
            icon: Icons.savings_outlined),
      ],
    );
  }

  Widget _opportunityCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [navyBlue, navyBlue.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: navyBlue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => widget.onNavigate?.call(1),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.water_drop_outlined,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Huile de palme raffinée',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'CMR → GAB · Forte demande',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: orange,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'Score 91',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: success, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '0% droits CEMAC · Marge estimée +18%',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => widget.onNavigate?.call(1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: navyBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: Text(
                      "Voir l'acheteur",
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
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
        onTap: _transactions.isEmpty
            ? null
            : () => _openTransaction(_transactions.first),
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

// ── Glass pill ──────────────────────────────────────────────────────────────

class _GlassPill extends StatelessWidget {
  final String label;
  const _GlassPill(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}

// ── Geometric background painter ────────────────────────────────────────────

class _HomeGeometry extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ring = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Rings top-right
    canvas.drawCircle(Offset(size.width + 10, -20), 160, ring);
    canvas.drawCircle(Offset(size.width + 10, -20), 108, ring);
    canvas.drawCircle(Offset(size.width + 10, -20), 60, ring);

    // Filled arc bottom-left
    canvas.drawCircle(
      Offset(-24, size.height * 0.85),
      72,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.04)
        ..style = PaintingStyle.fill,
    );

    // Dot cluster center-left
    final dot = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    for (final o in [
      Offset(size.width * 0.08, size.height * 0.45),
      Offset(size.width * 0.15, size.height * 0.55),
      Offset(size.width * 0.04, size.height * 0.60),
      Offset(size.width * 0.12, size.height * 0.68),
    ]) {
      canvas.drawCircle(o, 2.5, dot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
