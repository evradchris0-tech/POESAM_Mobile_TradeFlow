import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/mock_data.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import '../widgets/metric_card.dart';
import '../widgets/trust_score_ring.dart';

class ProfileScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;

  const ProfileScreen({super.key, this.onNavigate});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _plan = mockUser.plan;
  String _language = 'Français';

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
          setState(() => _plan = newPlan);
          _showSnack('Plan mis à jour vers $newPlan', bg: success);
        },
      ),
    );
  }

  void _openLanguageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _LanguageSheet(
        current: _language,
        onPick: (lang) {
          setState(() => _language = lang);
          _showSnack('Langue : $lang');
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
    _showSnack('Déconnecté · à bientôt Jean-Paul', bg: navyBlue);
  }

  @override
  Widget build(BuildContext context) {
    final u = mockUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.translate),
            tooltip: 'Langue',
            onPressed: _openLanguageSheet,
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
          CircleAvatar(
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
            child: LinearProgressIndicator(
              value: 0.62,
              minHeight: 6,
              backgroundColor: paleBlue,
              valueColor: const AlwaysStoppedAnimation<Color>(orange),
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
                border: Border.all(color: navyBlue.withOpacity(0.3)),
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
          border: Border.all(color: navyBlue.withOpacity(0.3)),
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

class _LanguageSheet extends StatelessWidget {
  final String current;
  final ValueChanged<String> onPick;

  const _LanguageSheet({required this.current, required this.onPick});

  static const _languages = [
    ('Français', '🇫🇷'),
    ('English', '🇬🇧'),
    ('العربية', '🇸🇦'),
    ('Wolof', '🇸🇳'),
    ('Bamanankan', '🇲🇱'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Langue de l\'application', style: AppText.h3()),
            ),
            const SizedBox(height: 8),
            for (final l in _languages)
              ListTile(
                leading: Text(l.$2, style: const TextStyle(fontSize: 20)),
                title: Text(l.$1, style: AppText.body(color: textPrimary)),
                trailing: l.$1 == current
                    ? const Icon(Icons.check, color: navyBlue)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  onPick(l.$1);
                },
              ),
          ],
        ),
      ),
    );
  }
}
