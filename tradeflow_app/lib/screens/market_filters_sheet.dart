import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

enum MarketSort {
  matchScore,
  volumeDesc,
  priceAsc,
  priceDesc,
  recent,
}

class MarketFilters {
  final Set<String> countries;
  final int minAnnualTons;
  final RangeValues priceRange;
  final bool verifiedOnly;
  final int minScore;
  final MarketSort sortBy;

  const MarketFilters({
    this.countries = const <String>{},
    this.minAnnualTons = 0,
    this.priceRange = const RangeValues(0, 50000),
    this.verifiedOnly = false,
    this.minScore = 0,
    this.sortBy = MarketSort.matchScore,
  });

  static const MarketFilters none = MarketFilters();

  bool get isActive =>
      countries.isNotEmpty ||
      minAnnualTons > 0 ||
      priceRange.start > 0 ||
      priceRange.end < 50000 ||
      verifiedOnly ||
      minScore > 0 ||
      sortBy != MarketSort.matchScore;

  int get activeChipsCount {
    int n = 0;
    if (countries.isNotEmpty) n++;
    if (minAnnualTons > 0) n++;
    if (priceRange.start > 0 || priceRange.end < 50000) n++;
    if (verifiedOnly) n++;
    if (minScore > 0) n++;
    if (sortBy != MarketSort.matchScore) n++;
    return n;
  }

  MarketFilters copyWith({
    Set<String>? countries,
    int? minAnnualTons,
    RangeValues? priceRange,
    bool? verifiedOnly,
    int? minScore,
    MarketSort? sortBy,
  }) {
    return MarketFilters(
      countries: countries ?? this.countries,
      minAnnualTons: minAnnualTons ?? this.minAnnualTons,
      priceRange: priceRange ?? this.priceRange,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      minScore: minScore ?? this.minScore,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

/// Affiche un bottom sheet de filtres. Retourne un [MarketFilters] mis à jour
/// (ou null si l'utilisateur ferme sans appliquer).
Future<MarketFilters?> showMarketFiltersSheet(
  BuildContext context,
  MarketFilters initial,
) {
  return showModalBottomSheet<MarketFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: surfacePrimary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _MarketFiltersSheet(initial: initial),
  );
}

class _MarketFiltersSheet extends StatefulWidget {
  final MarketFilters initial;
  const _MarketFiltersSheet({required this.initial});

  @override
  State<_MarketFiltersSheet> createState() => _MarketFiltersSheetState();
}

class _MarketFiltersSheetState extends State<_MarketFiltersSheet> {
  late MarketFilters _filters;

  static const _countries = <(String, String)>[
    ('CI', 'Côte d\'Ivoire'),
    ('SN', 'Sénégal'),
    ('GA', 'Gabon'),
    ('CG', 'Congo'),
    ('TD', 'Tchad'),
    ('NG', 'Nigeria'),
    ('MA', 'Maroc'),
    ('KE', 'Kenya'),
  ];

  static const _volumeOptions = <(int, String)>[
    (0, 'Tous'),
    (10, '≥ 10 t'),
    (50, '≥ 50 t'),
    (100, '≥ 100 t'),
    (500, '≥ 500 t'),
  ];

  static const _sortOptions = <(MarketSort, String, IconData)>[
    (MarketSort.matchScore, 'Match score', Icons.bolt_outlined),
    (MarketSort.volumeDesc, 'Volume décroissant', Icons.inventory_2_outlined),
    (MarketSort.priceAsc, 'Prix croissant', Icons.trending_up),
    (MarketSort.priceDesc, 'Prix décroissant', Icons.trending_down),
    (MarketSort.recent, 'Plus récent', Icons.schedule),
  ];

  @override
  void initState() {
    super.initState();
    _filters = widget.initial;
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() => _filters = MarketFilters.none);
  }

  void _apply() {
    HapticFeedback.lightImpact();
    Navigator.pop(context, _filters);
  }

  void _toggleCountry(String code) {
    HapticFeedback.selectionClick();
    final next = Set<String>.from(_filters.countries);
    if (next.contains(code)) {
      next.remove(code);
    } else {
      next.add(code);
    }
    setState(() => _filters = _filters.copyWith(countries: next));
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.88;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('Filtres', style: AppText.h2()),
                const Spacer(),
                if (_filters.isActive)
                  TextButton(
                    onPressed: _reset,
                    child: Text(
                      'Réinitialiser',
                      style: AppText.body(color: danger),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section('Pays cible'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _countries
                        .map((c) => _CountryChip(
                              code: c.$1,
                              name: c.$2,
                              selected: _filters.countries.contains(c.$1),
                              onTap: () => _toggleCountry(c.$1),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  _section('Volume annuel minimum'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _volumeOptions.map((v) {
                      final selected = _filters.minAnnualTons == v.$1;
                      return _SegmentChip(
                        label: v.$2,
                        selected: selected,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _filters =
                              _filters.copyWith(minAnnualTons: v.$1));
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  _section('Fourchette de prix (FCFA / kg)'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _filters.priceRange.start.round().toString(),
                        style: AppText.caption(color: navyBlue, weight: FontWeight.w600),
                      ),
                      Text(
                        '${_filters.priceRange.end.round()}+',
                        style: AppText.caption(color: navyBlue, weight: FontWeight.w600),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: _filters.priceRange,
                    min: 0,
                    max: 50000,
                    divisions: 50,
                    activeColor: orange,
                    inactiveColor: borderColor,
                    labels: RangeLabels(
                      _filters.priceRange.start.round().toString(),
                      _filters.priceRange.end.round().toString(),
                    ),
                    onChanged: (range) {
                      setState(() =>
                          _filters = _filters.copyWith(priceRange: range));
                    },
                  ),
                  const SizedBox(height: 16),
                  _section('Score de confiance minimum'),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _filters.minScore.toDouble(),
                          min: 0,
                          max: 99,
                          divisions: 99,
                          activeColor: navyBlue,
                          inactiveColor: borderColor,
                          onChanged: (v) {
                            setState(() => _filters =
                                _filters.copyWith(minScore: v.round()));
                          },
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        child: Text(
                          '${_filters.minScore}',
                          textAlign: TextAlign.right,
                          style: AppText.body(
                              color: navyBlue, weight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: surfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: navyBlue,
                      title: Text('Acheteurs vérifiés uniquement',
                          style: AppText.body(color: textPrimary)),
                      subtitle: Text(
                        'Filtre les comptes non encore KYC validés',
                        style: AppText.caption(),
                      ),
                      value: _filters.verifiedOnly,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        setState(() =>
                            _filters = _filters.copyWith(verifiedOnly: v));
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  _section('Trier par'),
                  Column(
                    children: _sortOptions.map((s) {
                      final selected = _filters.sortBy == s.$1;
                      return InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() =>
                              _filters = _filters.copyWith(sortBy: s.$1));
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? paleBlue
                                : surfaceSecondary,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected ? navyBlue : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(s.$3,
                                  size: 18,
                                  color:
                                      selected ? navyBlue : textTertiary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  s.$2,
                                  style: AppText.body(
                                    color: selected ? navyBlue : textPrimary,
                                    weight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                              if (selected)
                                const Icon(Icons.check_circle,
                                    color: navyBlue, size: 18),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + viewInsets),
            decoration: const BoxDecoration(
              color: surfacePrimary,
              border: Border(
                top: BorderSide(color: borderColor, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _apply,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: orange,
                    ),
                    child: Text(
                      _filters.isActive
                          ? 'Appliquer (${_filters.activeChipsCount})'
                          : 'Appliquer',
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

  Widget _section(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      child: Text(label.toUpperCase(), style: AppText.micro()),
    );
  }
}

class _CountryChip extends StatelessWidget {
  final String code;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  const _CountryChip({
    required this.code,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? paleBlue : surfaceSecondary,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? navyBlue : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: AppText.caption(
                color: selected ? navyBlue : textSecondary,
                weight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check, size: 14, color: navyBlue),
            ],
          ],
        ),
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? navyBlue : surfaceSecondary,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: AppText.caption(
            color: selected ? Colors.white : textSecondary,
            weight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
