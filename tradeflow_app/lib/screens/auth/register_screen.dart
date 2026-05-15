import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import 'verify_otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  // Champs optionnels PME
  final _businessNameCtrl = TextEditingController();
  final _rccmCtrl = TextEditingController();
  final _nifCtrl = TextEditingController();

  // Champ optionnel Acheteur
  final _companyNameCtrl = TextEditingController();

  String _selectedRole = 'pme';
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _businessNameCtrl.dispose();
    _rccmCtrl.dispose();
    _nifCtrl.dispose();
    _companyNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final email = _emailCtrl.text.trim();

      // Construit le payload metadata, incluant les champs optionnels
      // selon le role. Ces champs seront lus plus tard pour creer la ligne
      // pme_profiles ou buyer_profiles correspondante.
      final metadata = <String, dynamic>{
        'full_name':
            '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
        'role': _selectedRole,
        'phone': _phoneCtrl.text.trim(),
      };

      if (_selectedRole == 'pme') {
        if (_businessNameCtrl.text.trim().isNotEmpty) {
          metadata['business_name'] = _businessNameCtrl.text.trim();
        }
        if (_rccmCtrl.text.trim().isNotEmpty) {
          metadata['rccm'] = _rccmCtrl.text.trim();
        }
        if (_nifCtrl.text.trim().isNotEmpty) {
          metadata['nif'] = _nifCtrl.text.trim();
        }
      } else if (_selectedRole == 'buyer') {
        if (_companyNameCtrl.text.trim().isNotEmpty) {
          metadata['company_name'] = _companyNameCtrl.text.trim();
        }
      }

      await Supabase.instance.client.auth.signUp(
        email: email,
        password: _passCtrl.text,
        data: metadata,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyOtpScreen(email: email),
          ),
        );
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Une erreur inattendue est survenue');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfacePrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: navyBlue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Créer un compte', style: AppText.h1()),
                const SizedBox(height: 8),
                Text(
                  'Rejoignez le réseau TradeFlow Africa.',
                  style: AppText.body(color: textTertiary),
                ),
                const SizedBox(height: 32),

                // Sélecteur de Rôle (2 cartes verticales avec description)
                Text('Vous êtes', style: AppText.caption()),
                const SizedBox(height: 12),
                _roleCard(
                  label: 'Vendeur (PME)',
                  description:
                      'Vous produisez ou transformez des marchandises au Cameroun et souhaitez les exporter.',
                  icon: Icons.storefront,
                  role: 'pme',
                ),
                const SizedBox(height: 10),
                _roleCard(
                  label: 'Acheteur / Importateur',
                  description:
                      'Vous achetez depuis un autre pays africain pour importer des produits camerounais.',
                  icon: Icons.shopping_bag_outlined,
                  role: 'buyer',
                ),
                const SizedBox(height: 24),

                // Prénom et Nom
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        label: 'Prénom',
                        controller: _firstNameCtrl,
                        hint: 'Jean-Paul',
                        icon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(
                        label: 'Nom',
                        controller: _lastNameCtrl,
                        hint: 'Mboumba',
                        icon: Icons.badge_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Email
                _buildField(
                  label: 'Email professionnel',
                  controller: _emailCtrl,
                  hint: 'email@entreprise.com',
                  icon: Icons.email_outlined,
                  type: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),

                // Phone
                _buildField(
                  label: 'Téléphone (WhatsApp)',
                  controller: _phoneCtrl,
                  hint: '+237 6xx xxx xxx',
                  icon: Icons.phone_android,
                  type: TextInputType.phone,
                ),
                const SizedBox(height: 20),

                // Password
                Text('Mot de passe', style: AppText.caption()),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  style: AppText.body(),
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Mini 6 caractères' : null,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          size: 20),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),

                // Champs optionnels selon le rôle
                if (_selectedRole == 'pme') ..._pmeOptionalFields(),
                if (_selectedRole == 'buyer') ..._buyerOptionalFields(),

                const SizedBox(height: 40),

                // Submit Button
                ElevatedButton(
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Créer mon compte'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _pmeOptionalFields() {
    return [
      const SizedBox(height: 28),
      Row(
        children: [
          const Icon(Icons.info_outline, size: 14, color: textTertiary),
          const SizedBox(width: 6),
          Text(
            'Informations entreprise (optionnel)',
            style: AppText.caption(color: textTertiary),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _buildField(
        label: 'Nom de l\'entreprise',
        controller: _businessNameCtrl,
        hint: 'GIC Agro-Bafoussam',
        icon: Icons.business,
        required: false,
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: _buildField(
              label: 'RCCM',
              controller: _rccmCtrl,
              hint: 'RC/BFM/2020/B/1234',
              icon: Icons.description_outlined,
              required: false,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildField(
              label: 'NIF',
              controller: _nifCtrl,
              hint: 'P0123456789',
              icon: Icons.tag,
              required: false,
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buyerOptionalFields() {
    return [
      const SizedBox(height: 28),
      Row(
        children: [
          const Icon(Icons.info_outline, size: 14, color: textTertiary),
          const SizedBox(width: 6),
          Text(
            'Société (optionnel)',
            style: AppText.caption(color: textTertiary),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _buildField(
        label: 'Nom de la société',
        controller: _companyNameCtrl,
        hint: 'Société Commerciale Abidjan',
        icon: Icons.business,
        required: false,
      ),
    ];
  }

  Widget _roleCard({
    required String label,
    required String description,
    required IconData icon,
    required String role,
  }) {
    final isSelected = _selectedRole == role;
    return InkWell(
      onTap: () => setState(() => _selectedRole = role),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? navyBlue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? navyBlue : borderColor,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: navyBlue.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.18)
                    : paleBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : navyBlue,
                size: 22,
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
                          label,
                          style: AppText.body(
                            color: isSelected ? Colors.white : textPrimary,
                            weight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle,
                            color: Colors.white, size: 18),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppText.caption(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.85)
                          : textTertiary,
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

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
    bool required = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.caption()),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: type,
          style: AppText.body(),
          validator: required
              ? (v) => (v == null || v.isEmpty) ? 'Champ requis' : null
              : null,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
          ),
        ),
      ],
    );
  }
}
