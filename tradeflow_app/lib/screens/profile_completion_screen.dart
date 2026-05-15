import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';

/// Ecran de complétion du profil professionnel (PME).
/// Collecte RCCM, NIF, business_name, secteur — tous optionnels sauf
/// business_name (NOT NULL côté pme_profiles).
class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessCtrl = TextEditingController();
  final _rccmCtrl = TextEditingController();
  final _nifCtrl = TextEditingController();
  final _sectorCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  bool _loading = false;
  bool _initialFetch = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final row = await Supabase.instance.client
          .from('pme_profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      if (!mounted) return;
      if (row != null) {
        _businessCtrl.text = (row['business_name'] as String?) ?? '';
        _rccmCtrl.text = (row['rccm'] as String?) ?? '';
        _nifCtrl.text = (row['nif'] as String?) ?? '';
        _sectorCtrl.text = (row['sector'] as String?) ?? '';
        _regionCtrl.text = (row['region'] as String?) ?? '';
      }
    } catch (_) {
      // Ignoré : l'utilisateur remplit à neuf
    } finally {
      if (mounted) setState(() => _initialFetch = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      await Supabase.instance.client.from('pme_profiles').upsert({
        'user_id': user.id,
        'business_name': _businessCtrl.text.trim(),
        if (_rccmCtrl.text.trim().isNotEmpty) 'rccm': _rccmCtrl.text.trim(),
        if (_nifCtrl.text.trim().isNotEmpty) 'nif': _nifCtrl.text.trim(),
        if (_sectorCtrl.text.trim().isNotEmpty) 'sector': _sectorCtrl.text.trim(),
        if (_regionCtrl.text.trim().isNotEmpty) 'region': _regionCtrl.text.trim(),
      }, onConflict: 'user_id');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil professionnel enregistré'),
          backgroundColor: success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _businessCtrl.dispose();
    _rccmCtrl.dispose();
    _nifCtrl.dispose();
    _sectorCtrl.dispose();
    _regionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil pro')),
      body: _initialFetch
          ? const Center(child: CircularProgressIndicator(color: navyBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: paleBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: navyBlue, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Ces informations activent l\'escrow et le matching avec les acheteurs. Seul le nom est requis.',
                              style: AppText.caption(color: navyBlue),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _field(
                      label: 'Nom de l\'entreprise',
                      controller: _businessCtrl,
                      hint: 'GIC Agro-Bafoussam',
                      icon: Icons.business,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      label: 'RCCM (optionnel)',
                      controller: _rccmCtrl,
                      hint: 'RC/BFM/2020/B/1234',
                      icon: Icons.assignment_outlined,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      label: 'NIF (optionnel)',
                      controller: _nifCtrl,
                      hint: 'P012345678901',
                      icon: Icons.fingerprint,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      label: 'Secteur (optionnel)',
                      controller: _sectorCtrl,
                      hint: 'agro-alimentaire, épices-bio…',
                      icon: Icons.category_outlined,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      label: 'Région (optionnel)',
                      controller: _regionCtrl,
                      hint: 'Ouest, Littoral, Adamaoua…',
                      icon: Icons.location_on_outlined,
                    ),
                    if (_errorMsg != null) ...[
                      const SizedBox(height: 16),
                      Text(_errorMsg!, style: AppText.caption(color: danger)),
                    ],
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Enregistrer'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Plus tard',
                        style: AppText.body(color: textTertiary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.caption()),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
          ),
        ),
      ],
    );
  }
}
