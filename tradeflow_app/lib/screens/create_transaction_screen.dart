import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/tradeflow_api.dart';
import '../theme/app_theme.dart';
import '../utils/product_utils.dart';

/// Formulaire de création d'une nouvelle transaction commerciale.
/// Insère directement dans Supabase via [TradeFlowApi.createTransaction].
class CreateTransactionScreen extends StatefulWidget {
  const CreateTransactionScreen({super.key});

  @override
  State<CreateTransactionScreen> createState() => _CreateTransactionScreenState();
}

class _CreateTransactionScreenState extends State<CreateTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  String _selectedCorridor = 'CMR-CIV';
  String _selectedUnit = 'kg';
  bool _loading = false;

  static const _corridors = [
    ('CMR-CIV', 'Cameroun → Côte d\'Ivoire'),
    ('CMR-SEN', 'Cameroun → Sénégal'),
    ('CMR-GAB', 'Cameroun → Gabon'),
    ('CMR-NGA', 'Cameroun → Nigeria'),
    ('CMR-COG', 'Cameroun → Congo'),
  ];

  static const _units = ['kg', 'tonne', 'sac', 'carton', 'litre', 'pièce'];

  static const _products = [
    'Cacao', 'Café', 'Plantain', 'Manioc',
    'Huile de palme', 'Maïs', 'Arachides', 'Gingembre',
  ];

  int get _totalFcfa {
    final qty = int.tryParse(_qtyCtrl.text) ?? 0;
    final price = int.tryParse(_priceCtrl.text) ?? 0;
    return qty * price;
  }

  int get _commission => (_totalFcfa * 0.015).round();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await TradeFlowApi.instance.createTransaction(
        productName: _productCtrl.text.trim(),
        corridor: _selectedCorridor,
        quantity: int.parse(_qtyCtrl.text),
        unit: _selectedUnit,
        unitPriceFcfa: int.parse(_priceCtrl.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction créée avec succès !'),
            backgroundColor: success,
          ),
        );
        Navigator.pop(context, true); // true = refresh la liste parente
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle transaction')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Produit
            Text('Produit', style: AppText.caption()),
            const SizedBox(height: 8),
            _productSelector(),
            const SizedBox(height: 20),

            // Corridor
            Text('Corridor commercial', style: AppText.caption()),
            const SizedBox(height: 8),
            _corridorSelector(),
            const SizedBox(height: 20),

            // Quantité + Unité
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quantité', style: AppText.caption()),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _qtyCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: AppText.body(),
                        onChanged: (_) => setState(() {}),
                        validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                        decoration: const InputDecoration(hintText: 'ex: 500'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Unité', style: AppText.caption()),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedUnit,
                        style: AppText.body(),
                        decoration: const InputDecoration(),
                        items: _units.map((u) =>
                          DropdownMenuItem(value: u, child: Text(u))).toList(),
                        onChanged: (v) => setState(() => _selectedUnit = v!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Prix unitaire
            Text('Prix unitaire (FCFA)', style: AppText.caption()),
            const SizedBox(height: 8),
            TextFormField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppText.body(),
              onChanged: (_) => setState(() {}),
              validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              decoration: const InputDecoration(
                hintText: 'ex: 1200',
                prefixText: 'FCFA ',
              ),
            ),
            const SizedBox(height: 24),

            // Récapitulatif financier
            if (_totalFcfa > 0) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: paleBlue,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: navyBlue.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    _summaryRow('Sous-total', '${_fmt(_totalFcfa)} FCFA'),
                    _summaryRow('Commission TradeFlow (1.5%)', '${_fmt(_commission)} FCFA'),
                    const Divider(height: 20),
                    _summaryRow(
                      'Total estimé',
                      '${_fmt(_totalFcfa + _commission)} FCFA',
                      bold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Bouton
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _loading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Créer la transaction'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _productSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _products.map((p) {
        final isSelected = _productCtrl.text == p;
        return GestureDetector(
          onTap: () => setState(() => _productCtrl.text = p),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? navyBlue : surfacePrimary,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: isSelected ? navyBlue : borderColor,
                width: isSelected ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  productIconOf(p),
                  size: 13,
                  color: isSelected ? Colors.white : productColorOf(p),
                ),
                const SizedBox(width: 5),
                Text(
                  p,
                  style: AppText.caption(
                    color: isSelected ? Colors.white : textSecondary,
                    weight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _corridorSelector() {
    return Column(
      children: _corridors.map((c) {
        final isSelected = _selectedCorridor == c.$1;
        return InkWell(
          onTap: () => setState(() => _selectedCorridor = c.$1),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? paleBlue : surfacePrimary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? navyBlue : borderColor,
                width: isSelected ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.compare_arrows, size: 18, color: isSelected ? navyBlue : textTertiary),
                const SizedBox(width: 10),
                Text(c.$2, style: AppText.body(
                  color: isSelected ? navyBlue : textSecondary,
                  weight: isSelected ? FontWeight.bold : FontWeight.normal,
                )),
                const Spacer(),
                if (isSelected)
                  const Icon(Icons.check_circle, color: navyBlue, size: 18),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppText.caption()),
          Text(
            value,
            style: bold
                ? AppText.h3(color: navyBlue)
                : AppText.caption(color: textPrimary, weight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
