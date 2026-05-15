import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/product_utils.dart';

/// Données affichées par [ProductDetailScreen]. Standalone — peut être
/// construit depuis Supabase, mock data, ou une notification deep-link.
class ProductData {
  final String id;
  final String name;
  final String emoji;
  final String shCode;
  final String shDescription;
  final String unit;
  final int priceFcfa;
  final int minOrderQty;
  final int availableStock;
  final String description;
  final String origin;
  final String corridor;
  final List<String> certifications;
  final String vendorName;
  final String vendorCity;
  final int vendorTrustScore;
  final String? imageUrl;

  const ProductData({
    required this.id,
    required this.name,
    required this.emoji,
    required this.shCode,
    required this.shDescription,
    required this.unit,
    required this.priceFcfa,
    required this.minOrderQty,
    required this.availableStock,
    required this.description,
    required this.origin,
    required this.corridor,
    required this.certifications,
    required this.vendorName,
    required this.vendorCity,
    required this.vendorTrustScore,
    this.imageUrl,
  });

  static const ProductData demo = ProductData(
    id: 'bbbbbbbb-0001-0001-0001-000000000001',
    name: 'Plantain séché sous vide',
    emoji: '🍌',
    shCode: '0803.10',
    shDescription: 'Bananes plantain, séchées',
    unit: 'kg',
    priceFcfa: 3100,
    minOrderQty: 100,
    availableStock: 5000,
    description:
        'Plantain séché sous vide selon les normes MINADER. Conditionnement '
        'sachet alu 1 kg, durée de conservation 12 mois. Production '
        'mensuelle 5 tonnes. Livraison Douala possible sous 7 jours.',
    origin: 'Bafoussam, Ouest Cameroun',
    corridor: 'CMR → CIV',
    certifications: ['MINADER_certifié', 'Zéro déforestation'],
    vendorName: 'GIC Agro-Bafoussam',
    vendorCity: 'Bafoussam',
    vendorTrustScore: 82,
  );
}

class ProductDetailScreen extends StatefulWidget {
  final ProductData product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _favorite = false;

  void _share() {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Partage de #${widget.product.id} — bientôt'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: navyBlue,
      ),
    );
  }

  void _toggleFavorite() {
    HapticFeedback.mediumImpact();
    setState(() => _favorite = !_favorite);
  }

  void _requestQuote() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _QuoteRequestSheet(product: widget.product),
    );
  }

  void _openChat() {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Discussion vendeur — bientôt'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: navyBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final stockColor = p.availableStock > 1000
        ? success
        : p.availableStock > 100
            ? warning
            : danger;
    final stockLabel = p.availableStock > 1000
        ? 'En stock'
        : p.availableStock > 100
            ? 'Stock limité'
            : 'Bientôt épuisé';

    return Scaffold(
      backgroundColor: surfaceSecondary,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            backgroundColor: surfacePrimary,
            foregroundColor: navyBlue,
            iconTheme: const IconThemeData(color: navyBlue),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: _share,
              ),
              IconButton(
                icon: Icon(
                  _favorite ? Icons.favorite : Icons.favorite_border,
                  color: _favorite ? danger : navyBlue,
                ),
                onPressed: _toggleFavorite,
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _heroImage(p),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: surfacePrimary,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(p.name, style: AppText.h1()),
                      ),
                      _shCodeBadge(p.shCode),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(p.shDescription, style: AppText.caption()),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatFCFA(p.priceFcfa),
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: orange,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('/${p.unit}',
                            style:
                                AppText.body(color: textTertiary)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: stockColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: stockColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(stockLabel,
                                style: AppText.micro(color: stockColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Commande min. ${p.minOrderQty} ${p.unit} · ${p.availableStock} ${p.unit} disponibles',
                    style: AppText.caption(),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surfacePrimary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 0.5),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: paleBlue,
                    child: Text(
                      _initials(p.vendorName),
                      style: AppText.body(
                          color: navyBlue, weight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.vendorName,
                            style: AppText.body(
                                color: textPrimary,
                                weight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 12, color: textTertiary),
                            const SizedBox(width: 2),
                            Text(p.vendorCity,
                                style: AppText.caption()),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _trustChip(p.vendorTrustScore),
                ],
              ),
            ),
          ),
          if (p.certifications.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Certifications', style: AppText.h3()),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: p.certifications
                          .map((c) => _certChip(c))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Description', style: AppText.h3()),
                  const SizedBox(height: 8),
                  Text(p.description,
                      style: AppText.body(color: textSecondary)),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Informations', style: AppText.h3()),
                  const SizedBox(height: 12),
                  _infoRow(Icons.public, 'Origine', p.origin),
                  _infoRow(Icons.compare_arrows, 'Corridor', p.corridor),
                  _infoRow(Icons.qr_code_2, 'Code SH',
                      '${p.shCode} — ${p.shDescription}'),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _actionBar(),
    );
  }

  Widget _heroImage(ProductData p) {
    if (p.imageUrl != null && p.imageUrl!.isNotEmpty) {
      return Image.network(
        p.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholderHero(p),
      );
    }
    return _placeholderHero(p);
  }

  Widget _placeholderHero(ProductData p) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [paleBlue, surfacePrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          productIconOf(p.name),
          size: 80,
          color: productColorOf(p.name).withValues(alpha: 0.55),
        ),
      ),
    );
  }

  Widget _shCodeBadge(String code) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: paleBlue,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'SH $code',
        style: GoogleFonts.firaCode(
          fontSize: 11,
          color: navyBlue,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _trustChip(int score) {
    final color = score >= 80
        ? success
        : score >= 50
            ? orange
            : danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$score/100',
            style: AppText.caption(color: color, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _certChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: successBg,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: success.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_outlined, size: 14, color: success),
          const SizedBox(width: 4),
          Text(label,
              style: AppText.caption(
                  color: successText, weight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: navyBlue),
          const SizedBox(width: 10),
          SizedBox(
            width: 88,
            child: Text(label, style: AppText.caption()),
          ),
          Expanded(
            child:
                Text(value, style: AppText.body(color: textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _actionBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: surfacePrimary,
        border: Border(top: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              onPressed: _openChat,
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Discuter'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: ElevatedButton.icon(
              onPressed: _requestQuote,
              icon: const Icon(Icons.request_quote_outlined, size: 18),
              label: const Text('Demander un devis'),
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts =
        name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class _QuoteRequestSheet extends StatefulWidget {
  final ProductData product;
  const _QuoteRequestSheet({required this.product});

  @override
  State<_QuoteRequestSheet> createState() => _QuoteRequestSheetState();
}

class _QuoteRequestSheetState extends State<_QuoteRequestSheet> {
  late TextEditingController _qtyCtrl;
  final _notesCtrl = TextEditingController();
  bool _submitting = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(
        text: widget.product.minOrderQty.toString());
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  int get _qty => int.tryParse(_qtyCtrl.text) ?? 0;
  int get _total => _qty * widget.product.priceFcfa;

  Future<void> _submit() async {
    HapticFeedback.mediumImpact();
    if (_qty < widget.product.minOrderQty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Quantité minimale : ${widget.product.minOrderQty} ${widget.product.unit}'),
          backgroundColor: danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _sent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _sent ? _successView() : _formView(),
        ),
      ),
    );
  }

  Widget _formView() {
    return Column(
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
        const SizedBox(height: 14),
        Text('Demande de devis', style: AppText.h2()),
        const SizedBox(height: 4),
        Text(widget.product.name,
            style: AppText.body(color: textTertiary)),
        const SizedBox(height: 20),
        Text('Quantité (${widget.product.unit})',
            style: AppText.caption()),
        const SizedBox(height: 8),
        TextField(
          controller: _qtyCtrl,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20),
            suffixText: widget.product.unit,
          ),
        ),
        const SizedBox(height: 16),
        Text('Notes pour le vendeur', style: AppText.caption()),
        const SizedBox(height: 8),
        TextField(
          controller: _notesCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Délai souhaité, conditionnement, certifications...',
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: paleBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              _line('Prix unitaire',
                  '${formatFCFA(widget.product.priceFcfa)}/${widget.product.unit}'),
              const SizedBox(height: 6),
              _line('Quantité', '$_qty ${widget.product.unit}'),
              const Divider(height: 18),
              _line(
                'Sous-total estimé',
                formatFCFA(_total),
                strong: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: orange,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Envoyer la demande'),
          ),
        ),
      ],
    );
  }

  Widget _successView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 500),
          curve: Curves.elasticOut,
          builder: (_, value, __) => Transform.scale(
            scale: value,
            child: Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  color: successBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: success, size: 44),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Demande envoyée',
            style: AppText.h2(), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'Le vendeur recevra votre demande et reviendra vers vous sous 24 à 48h.',
          style: AppText.body(color: textTertiary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Fermer'),
          ),
        ),
      ],
    );
  }

  Widget _line(String label, String value, {bool strong = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppText.caption(
                color: strong ? navyBlue : textSecondary,
                weight: strong ? FontWeight.w600 : FontWeight.w400)),
        Text(value,
            style: strong
                ? AppText.body(color: navyBlue, weight: FontWeight.w700)
                : AppText.caption(color: textPrimary)),
      ],
    );
  }
}
