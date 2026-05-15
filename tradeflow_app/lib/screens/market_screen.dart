import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/mock_data.dart';
import '../models/buyer.dart';
import '../services/tradeflow_api.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton.dart';
import 'market_filters_sheet.dart';

class MarketScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;

  const MarketScreen({super.key, this.onNavigate});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  String _selectedProduct = 'Plantain';
  String _selectedCountry = 'Côte d\'Ivoire';
  int _targetQty = 1000;
  int _targetPrice = 1200;
  final _searchCtrl = TextEditingController();
  bool _loading = true;
  bool _filtering = false;

  static const List<String> _countries = [
    'Côte d\'Ivoire',
    'Sénégal',
    'Gabon',
    'Nigeria',
    'Ghana',
    'Mali',
    'RDC',
  ];

  List<Buyer> _fetchedBuyers = [];
  MarketFilters _filters = MarketFilters.none;

  @override
  void initState() {
    super.initState();
    _loadBuyers();
    _searchCtrl.addListener(() => setState(() {}));
  }

  Future<void> _loadBuyers() async {
    setState(() {
      _loading = true;
      _fetchedBuyers = [];
    });
    try {
      final buyers = await TradeFlowApi.instance.fetchMarketBuyers(_selectedProduct);
      if (mounted) {
        setState(() {
          _fetchedBuyers = buyers;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickProduct(String p) async {
    if (p == _selectedProduct) return;
    setState(() {
      _selectedProduct = p;
      _filtering = true;
    });
    await _loadBuyers();
    if (mounted) setState(() => _filtering = false);
  }

  void _pickCountry() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _CountrySheet(
        selected: _selectedCountry,
        items: _countries,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedCountry = picked);
    }
  }

  List<Buyer> get _filteredBuyers {
    final q = _searchCtrl.text.trim().toLowerCase();
    List<Buyer> list = _fetchedBuyers;

    if (q.isNotEmpty) {
      list = list.where((b) {
        return b.name.toLowerCase().contains(q) ||
            b.city.toLowerCase().contains(q) ||
            b.contactName.toLowerCase().contains(q) ||
            b.country.toLowerCase().contains(q);
      }).toList();
    }

    if (_filters.countries.isNotEmpty) {
      list = list
          .where((b) => _filters.countries.contains(_countryCode(b.country)))
          .toList();
    }

    if (_filters.minAnnualTons > 0) {
      list = list
          .where((b) => b.annualImportTons >= _filters.minAnnualTons)
          .toList();
    }

    if (_filters.priceRange.start > 0 || _filters.priceRange.end < 50000) {
      list = list.where((b) {
        final overlap = b.priceRangeMax >= _filters.priceRange.start &&
            b.priceRangeMin <= _filters.priceRange.end;
        return overlap;
      }).toList();
    }

    if (_filters.verifiedOnly) {
      list = list.where((b) => b.isVerified).toList();
    }

    if (_filters.minScore > 0) {
      list = list.where((b) => _computeMatch(b) >= _filters.minScore).toList();
    }

    switch (_filters.sortBy) {
      case MarketSort.matchScore:
        list.sort((a, b) => _computeMatch(b).compareTo(_computeMatch(a)));
        break;
      case MarketSort.volumeDesc:
        list.sort((a, b) => b.annualImportTons.compareTo(a.annualImportTons));
        break;
      case MarketSort.priceAsc:
        list.sort((a, b) => a.priceRangeMin.compareTo(b.priceRangeMin));
        break;
      case MarketSort.priceDesc:
        list.sort((a, b) => b.priceRangeMax.compareTo(a.priceRangeMax));
        break;
      case MarketSort.recent:
        // Pas de date de création sur Buyer mock ; on garde l'ordre de la liste
        break;
    }

    return list;
  }

  /// 'Côte d\'Ivoire' / '🇨🇮 Côte d\'Ivoire' → 'CI'.
  String _countryCode(String name) {
    final n = name.toLowerCase();
    if (n.contains('ivoir')) { return 'CI'; }
    if (n.contains('sénégal') || n.contains('senegal')) { return 'SN'; }
    if (n.contains('gabon')) { return 'GA'; }
    if (n.contains('congo')) { return 'CG'; }
    if (n.contains('tchad') || n.contains('chad')) { return 'TD'; }
    if (n.contains('nigeria')) { return 'NG'; }
    if (n.contains('maroc') || n.contains('morocco')) { return 'MA'; }
    if (n.contains('kenya')) { return 'KE'; }
    if (n.contains('mali')) { return 'ML'; }
    if (n.contains('ghana')) { return 'GH'; }
    return name.length >= 2 ? name.substring(0, 2).toUpperCase() : 'XX';
  }

  int _computeMatch(Buyer b) {
    int score = 50; // Base de confiance

    // Critère Prix : L'acheteur a-t-il le budget ?
    if (_targetPrice >= b.priceRangeMin && _targetPrice <= b.priceRangeMax) {
      score += 35; // Perfect match
    } else {
      final diff = (_targetPrice - b.priceRangeMax).abs();
      if (diff <= 100) { score += 15; }
      else if (diff <= 250) { score += 5; }
    }

    // Critère Quantité : Le volume annuel est-il suffisant ?
    final tons = _targetQty / 1000;
    if (b.annualImportTons >= tons * 5) { score += 10; }
    else if (b.annualImportTons >= tons) { score += 5; }

    if (b.isVerified) { score += 5; }

    // Pseudo-randomisation pour faire naturel
    score += (b.name.length % 4);

    return score.clamp(10, 99);
  }

  Color _scoreColor(int score) {
    if (score > 80) return success;
    if (score > 60) return orange;
    return danger;
  }

  void _openContact(Buyer b) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _QuoteSheet(buyer: b, product: _selectedProduct),
    );
  }

  void _newSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _NewSearchSheet(
        onSubmit: (product, country, qty, price) {
          setState(() {
            _selectedProduct = product;
            _selectedCountry = country;
            _targetQty = qty;
            _targetPrice = price;
            _filtering = true;
          });
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) setState(() => _filtering = false);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trouver un acheteur'),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.tune_outlined),
                tooltip: 'Filtres avancés',
                onPressed: () async {
                  final updated =
                      await showMarketFiltersSheet(context, _filters);
                  if (updated == null || !mounted) return;
                  setState(() {
                    _filters = updated;
                    _filtering = true;
                  });
                  Future.delayed(const Duration(milliseconds: 400), () {
                    if (mounted) setState(() => _filtering = false);
                  });
                },
              ),
              if (_filters.isActive)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: appBarSurface, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const ListSkeleton(count: 5, itemHeight: 110)
          : _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: orange,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add),
        label: Text(
          'Nouvelle recherche',
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        onPressed: _newSearch,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildBody() {
    final buyers = _filteredBuyers;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Rechercher acheteur, ville, contact...',
              prefixIcon:
                  const Icon(Icons.search, color: textTertiary, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        FocusScope.of(context).unfocus();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: inputBorderColor, width: 0.8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: inputBorderColor, width: 0.8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: navyBlue, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: mockProducts.map((p) {
              final selected = p == _selectedProduct;
              return FilterChip(
                label: Text(p),
                selected: selected,
                onSelected: (_) => _pickProduct(p),
                selectedColor: paleBlue,
                backgroundColor: surfacePrimary,
                checkmarkColor: navyBlue,
                side: BorderSide(
                  color: selected ? navyBlue : borderColor,
                  width: selected ? 1 : 0.5,
                ),
                labelStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? navyBlue : textSecondary,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Destination :',
                style: GoogleFonts.inter(fontSize: 13, color: textSecondary),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(99),
                onTap: _pickCountry,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: paleBlue,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedCountry,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: navyBlue,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.expand_more, size: 16, color: navyBlue),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: paleBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${buyers.length} acheteur${buyers.length > 1 ? 's' : ''} identifié${buyers.length > 1 ? 's' : ''} · '
              'Produit : $_selectedProduct',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: navyBlue,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_filtering)
            ...List.generate(
              3,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: SkeletonBlock(height: 110),
              ),
            )
          else if (buyers.isEmpty)
            EmptyState(
              compact: true,
              icon: Icons.search_off,
              iconColor: textTertiary,
              title: 'Aucun acheteur trouvé',
              subtitle: _filters.isActive
                  ? 'Essayez d\'assouplir vos filtres.'
                  : 'Affinez votre recherche ou changez de produit.',
              buttonLabel: _filters.isActive ? 'Réinitialiser les filtres' : 'Modifier la recherche',
              buttonIcon: _filters.isActive ? Icons.filter_alt_off : Icons.tune,
              onAction: _filters.isActive
                  ? () => setState(() => _filters = MarketFilters.none)
                  : _newSearch,
            )
          else
            ...buyers.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buyerCard(b),
              ),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: surfaceSecondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_shipping_outlined,
                    color: navyBlue, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Transport estimé : 8 jours · 85 000 FCFA via AGL',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buyerCard(Buyer b) {
    final color = _scoreColor(b.score);
    return InkWell(
      onTap: () => _openContact(b),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surfacePrimary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: b.avatarColor,
              child: Text(
                b.initials,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
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
                          b.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      if (b.isVerified) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: successBg,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified,
                                  size: 11, color: success),
                              const SizedBox(width: 3),
                              Text(
                                'Vérifié',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: successText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${b.contactName} · ${b.city}, ${b.country}',
                    style: GoogleFonts.inter(fontSize: 12, color: textTertiary),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 14, color: color),
                        const SizedBox(width: 6),
                        Text(
                          'Match IA : ${_computeMatch(b)}%',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${b.annualImportTons}T/an · ${b.priceRangeMin}-${b.priceRangeMax} FCFA/kg',
                    style: GoogleFonts.inter(fontSize: 11, color: textTertiary),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton(
                      onPressed: () => _openContact(b),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: navyBlue,
                        side: const BorderSide(color: navyBlue, width: 1),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Contacter',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: navyBlue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountrySheet extends StatelessWidget {
  final String selected;
  final List<String> items;

  const _CountrySheet({required this.selected, required this.items});

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
              child: Text('Pays de destination', style: AppText.h3()),
            ),
            const SizedBox(height: 8),
            for (final c in items)
              ListTile(
                title: Text(c, style: AppText.body(color: textPrimary)),
                trailing: c == selected
                    ? const Icon(Icons.check, color: navyBlue)
                    : null,
                onTap: () => Navigator.pop(context, c),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuoteSheet extends StatefulWidget {
  final Buyer buyer;
  final String product;

  const _QuoteSheet({required this.buyer, required this.product});

  @override
  State<_QuoteSheet> createState() => _QuoteSheetState();
}

class _QuoteSheetState extends State<_QuoteSheet> {
  late final TextEditingController _qty;
  late final TextEditingController _price;
  final _message = TextEditingController(
    text:
        'Bonjour, je suis intéressé par une commande. Pourriez-vous confirmer la disponibilité ?',
  );
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _qty = TextEditingController(text: '500');
    _price =
        TextEditingController(text: widget.buyer.priceRangeMin.toString());
  }

  @override
  void dispose() {
    _qty.dispose();
    _price.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text('Demande envoyée à ${widget.buyer.name}')),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.buyer;
    final qty = int.tryParse(_qty.text) ?? 0;
    final price = int.tryParse(_price.text) ?? 0;
    final total = qty * price;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: SingleChildScrollView(
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
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: b.avatarColor,
                    child: Text(
                      b.initials,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.name, style: AppText.h3()),
                        Text(
                          '${b.contactName} · ${b.city}, ${b.country}',
                          style: AppText.caption(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('PRODUIT', style: AppText.micro()),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: paleBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.product,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: navyBlue,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('QUANTITÉ (kg)', style: AppText.micro()),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _qty,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          decoration:
                              const InputDecoration(hintText: 'ex: 500'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PRIX/KG (FCFA)', style: AppText.micro()),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _price,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText:
                                '${b.priceRangeMin}-${b.priceRangeMax}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: surfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Montant estimé',
                        style: AppText.body(color: textSecondary)),
                    Text(
                      formatFCFA(total),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: navyBlue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('MESSAGE', style: AppText.micro()),
              const SizedBox(height: 6),
              TextField(
                controller: _message,
                maxLines: 3,
                decoration:
                    const InputDecoration(hintText: 'Votre message...'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send, size: 16),
                  onPressed: _sending ? null : _send,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  label: _sending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Envoyer la demande'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewSearchSheet extends StatefulWidget {
  final void Function(String product, String country, int qty, int price) onSubmit;

  const _NewSearchSheet({required this.onSubmit});

  @override
  State<_NewSearchSheet> createState() => _NewSearchSheetState();
}

class _NewSearchSheetState extends State<_NewSearchSheet> {
  String _product = 'Cacao';
  String _country = 'Côte d\'Ivoire';
  final _qty = TextEditingController(text: '1000');
  final _price = TextEditingController(text: '1200');
  bool _searching = false;

  static const _countries = [
    'Côte d\'Ivoire',
    'Sénégal',
    'Gabon',
    'Nigeria',
    'Ghana',
  ];

  @override
  void dispose() {
    _qty.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _launch() async {
    setState(() => _searching = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    final qty = int.tryParse(_qty.text) ?? 1000;
    final price = int.tryParse(_price.text) ?? 1200;
    widget.onSubmit(_product, _country, qty, price);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recherche lancée · $_product → $_country'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: navyBlue,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
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
            Text('Nouvelle recherche', style: AppText.h2()),
            const SizedBox(height: 4),
            Text(
              'Identifie les meilleurs acheteurs pour ton produit',
              style: AppText.caption(),
            ),
            const SizedBox(height: 16),
            Text('PRODUIT', style: AppText.micro()),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: mockProducts.map((p) {
                final sel = p == _product;
                return ChoiceChip(
                  label: Text(p),
                  selected: sel,
                  onSelected: (_) => setState(() => _product = p),
                  selectedColor: paleBlue,
                  side: BorderSide(
                    color: sel ? navyBlue : borderColor,
                    width: sel ? 1 : 0.5,
                  ),
                  labelStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                    color: sel ? navyBlue : textSecondary,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('DESTINATION', style: AppText.micro()),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _countries.map((c) {
                final sel = c == _country;
                return ChoiceChip(
                  label: Text(c),
                  selected: sel,
                  onSelected: (_) => setState(() => _country = c),
                  selectedColor: paleBlue,
                  side: BorderSide(
                    color: sel ? navyBlue : borderColor,
                    width: sel ? 1 : 0.5,
                  ),
                  labelStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                    color: sel ? navyBlue : textSecondary,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('QUANTITÉ (kg)', style: AppText.micro()),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _qty,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'ex: 1000'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PRIX CIBLE (FCFA)', style: AppText.micro()),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _price,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'ex: 1200'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.search, size: 18),
                onPressed: _searching ? null : _launch,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                label: _searching
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Lancer la recherche'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
