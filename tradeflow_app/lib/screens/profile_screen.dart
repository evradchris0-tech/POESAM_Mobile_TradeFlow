import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/demo_config.dart';
import '../models/user_profile.dart';
import '../services/tradeflow_api.dart';
import '../theme/app_theme.dart';
import '../widgets/metric_card.dart';
import '../widgets/skeleton.dart';
import '../widgets/trust_score_ring.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;

  const ProfileScreen({super.key, this.onNavigate});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _user;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await TradeFlowApi.instance.fetchUserProfile();
      if (!mounted) return;
      setState(() {
        _user = user;
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

  String? _planOverride;
  String get _plan => _planOverride ?? _user?.plan ?? 'Pro';

  void _showSnack(String msg, {Color? bg}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: bg ?? navyBlue,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _openUpgradeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _PlanSheet(
        current: _plan,
        onPick: (newPlan) {
          setState(() => _planOverride = newPlan);
          _showSnack('Plan mis à jour vers $newPlan', bg: success);
        },
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Se déconnecter'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: danger),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    
    // Vraie déconnexion Supabase
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mon profil')),
        body: const ProfileSkeleton(),
      );
    }
    if (_error != null || _user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mon profil')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: danger),
                const SizedBox(height: 12),
                Text(
                  'Impossible de charger le profil',
                  style: AppText.h3(),
                ),
                const SizedBox(height: 8),
                Text(
                  _error ?? 'Erreur inconnue',
                  textAlign: TextAlign.center,
                  style: AppText.caption(),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadProfile,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final u = _user!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Paramètres',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(u),
            const SizedBox(height: 20),
            _planCard(u),
            const SizedBox(height: 12),
            _trustCard(u),
            const SizedBox(height: 20),
            Text('Métriques de réputation', style: AppText.h3()),
            const SizedBox(height: 12),
            _metricsGrid(u),
            const SizedBox(height: 24),
            Text('Mes corridors actifs', style: AppText.h3()),
            const SizedBox(height: 10),
            _corridors(u),
            const SizedBox(height: 24),
            Text('Documents KYC', style: AppText.h3()),
            const SizedBox(height: 10),
            _kycCard(u),
            const SizedBox(height: 20),
            _creditAccess(),
            const SizedBox(height: 24),
            Text('Paramètres', style: AppText.h3()),
            const SizedBox(height: 10),
            SwitchListTile(
              value: DemoConfig.kUseMockFallback,
              activeThumbColor: navyBlue,
              contentPadding: const EdgeInsets.symmetric(horizontal: 0),
              title: Row(
                children: [
                  const Icon(Icons.bug_report_outlined, color: textSecondary, size: 22),
                  const SizedBox(width: 12),
                  Flexible(child: Text('Mode Démo (Données simulées)', style: AppText.body())),
                ],
              ),
              onChanged: (val) {
                setState(() => DemoConfig.kUseMockFallback = val);
                _showSnack(val ? 'Mode Démo activé (Mocks)' : 'Temps réel activé', bg: val ? warning : success);
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout, size: 18),
                onPressed: _logout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: danger,
                  side: const BorderSide(color: danger),
                  minimumSize: const Size.fromHeight(44),
                ),
                label: const Text('Se déconnecter'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(UserProfile u) {
    return Center(
      child: Column(
        children: [
          Hero(
            tag: 'profile-avatar',
            child: CircleAvatar(
              radius: 40,
              backgroundColor: navyBlue,
              child: Text(
                u.initials,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(u.fullName, style: AppText.h2()),
          const SizedBox(height: 4),
          Text(u.company, style: AppText.body(color: textTertiary)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: paleBlue,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              u.trustLevel,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: navyBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _planCard(UserProfile u) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_outline, color: orange, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan $_plan',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: navyBlue,
                  ),
                ),
                Text(
                  _plan == 'Premium'
                      ? 'Plan illimité'
                      : 'Actif jusqu\'au ${u.planExpiry}',
                  style: GoogleFonts.inter(fontSize: 12, color: textTertiary),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: _openUpgradeSheet,
            style: OutlinedButton.styleFrom(
              foregroundColor: navyBlue,
              side: const BorderSide(color: navyBlue),
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Gérer'),
          ),
        ],
      ),
    );
  }

  Widget _trustCard(UserProfile u) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        children: [
          TrustScoreRing(trustScore: u.trustScore),
          const SizedBox(height: 16),
          Text(
            u.trustLevel,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Plus que ${u.levelsToNext} niveaux pour atteindre ${u.nextLevel}',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: textTertiary),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Niveau actuel',
                style: GoogleFonts.inter(fontSize: 11, color: textTertiary),
              ),
              Text(
                u.nextLevel,
                style: GoogleFonts.inter(fontSize: 11, color: textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: const LinearProgressIndicator(
              value: 0.62,
              minHeight: 6,
              backgroundColor: paleBlue,
              valueColor: AlwaysStoppedAnimation<Color>(orange),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '62 % du prochain niveau',
              style: GoogleFonts.inter(fontSize: 11, color: textTertiary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricsGrid(UserProfile u) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: [
        MetricCard(value: '${u.transactionsSuccess}', label: 'Transactions réussies'),
        MetricCard(value: '${u.deliveryRate.toStringAsFixed(0)} %', label: 'Taux de livraison'),
        MetricCard(
          value: '${u.avgDeliveryDays.toString().replaceAll('.', ',')} jours',
          label: 'Délai moyen',
        ),
        MetricCard(value: '${u.disputes}', label: 'Litiges'),
      ],
    );
  }

  Widget _corridors(UserProfile u) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: u.activeCorridors
          .map(
            (c) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: paleBlue,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: navyBlue.withValues(alpha: 0.3)),
              ),
              child: Text(
                c,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: navyBlue,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _kycCard(UserProfile u) {
    return Container(
      decoration: BoxDecoration(
        color: surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (int i = 0; i < u.kycDocuments.length; i++) ...[
            ListTile(
              dense: true,
              leading: const Icon(Icons.check_circle, color: success, size: 22),
              title: Text(
                u.kycDocuments[i].name,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: successBg,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  u.kycDocuments[i].status,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: successText,
                  ),
                ),
              ),
            ),
            if (i < u.kycDocuments.length - 1)
              const Divider(height: 1, indent: 56, endIndent: 16),
          ],
        ],
      ),
    );
  }

  Widget _creditAccess() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showSnack('Module crédit bientôt disponible'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: paleBlue,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: navyBlue.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Accès au crédit disponible',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: navyBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Votre Trust Score vous donne accès à des lignes de crédit.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward, color: navyBlue),
          ],
        ),
      ),
    );
  }
}

class _PlanOption {
  final String name;
  final String price;
  final String description;
  final List<String> features;
  final bool highlighted;

  const _PlanOption({
    required this.name,
    required this.price,
    required this.description,
    required this.features,
    this.highlighted = false,
  });
}

class _PlanSheet extends StatelessWidget {
  final String current;
  final ValueChanged<String> onPick;

  const _PlanSheet({required this.current, required this.onPick});

  static const _plans = [
    _PlanOption(
      name: 'Starter',
      price: 'Gratuit',
      description: 'Découverte de la plateforme',
      features: [
        '2 transactions/mois',
        'Commission 2,5 %',
        'Support email',
      ],
    ),
    _PlanOption(
      name: 'Pro',
      price: '25 000 FCFA/mois',
      description: 'Pour exportateurs réguliers',
      features: [
        'Transactions illimitées',
        'Commission 1,5 %',
        'Guide douanier IA',
        'Support prioritaire',
      ],
      highlighted: true,
    ),
    _PlanOption(
      name: 'Premium',
      price: '75 000 FCFA/mois',
      description: 'Pour gros volumes',
      features: [
        'Commission 0,8 %',
        'Accès crédit prioritaire',
        'Account manager dédié',
        'API & intégrations',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Choisir un plan', style: AppText.h2()),
            const SizedBox(height: 4),
            Text(
              'Adaptez votre abonnement à votre activité.',
              style: AppText.caption(),
            ),
            const SizedBox(height: 16),
            for (final p in _plans) ...[
              _planRow(context, p),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  Widget _planRow(BuildContext context, _PlanOption p) {
    final isCurrent = p.name == current;
    final highlighted = p.highlighted;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlighted ? paleBlue : surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted ? navyBlue : borderColor,
          width: highlighted ? 1.2 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          p.name,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: navyBlue,
                          ),
                        ),
                        if (highlighted) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: orange,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              'Populaire',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(p.description, style: AppText.caption()),
                  ],
                ),
              ),
              Text(
                p.price,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final f in p.features)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check, size: 14, color: success),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      f,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isCurrent
                  ? null
                  : () {
                      Navigator.pop(context);
                      onPick(p.name);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrent
                    ? surfaceSecondary
                    : (highlighted ? orange : navyBlue),
                foregroundColor: isCurrent ? textTertiary : Colors.white,
                disabledBackgroundColor: surfaceSecondary,
                disabledForegroundColor: textTertiary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(isCurrent ? 'Plan actuel' : 'Choisir ${p.name}'),
            ),
          ),
        ],
      ),
    );
  }
}

