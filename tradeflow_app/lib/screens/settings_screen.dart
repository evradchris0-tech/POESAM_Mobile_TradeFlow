import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/demo_config.dart';
import '../services/biometric_service.dart';
import '../theme/app_theme.dart';
import 'auth/forgot_password_screen.dart';
import 'edit_profile_screen.dart';
import 'kyc_flow_screen.dart';
import 'profile_completion_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _biometric    = false;
  bool _bioAvailable = false;
  bool _demoMode = DemoConfig.kUseMockFallback;
  String _language = 'Français';
  String _theme = 'Système';

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final available = await BiometricService.instance.isAvailable();
    final enabled   = await BiometricService.instance.isEnabled();
    if (!mounted) return;
    setState(() {
      _bioAvailable = available;
      _biometric    = enabled;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    HapticFeedback.selectionClick();
    if (!value) {
      await BiometricService.instance.disable();
      if (mounted) setState(() => _biometric = false);
      return;
    }
    // Enabling: check if credentials are already stored
    final creds = await BiometricService.instance.getCredentials();
    if (creds != null) {
      await BiometricService.instance.setEnabled(true);
      if (mounted) setState(() => _biometric = true);
      return;
    }
    // No stored creds — ask for password first
    if (!mounted) return;
    final password = await _askPassword();
    if (password == null || !mounted) return;
    final email = Supabase.instance.client.auth.currentUser?.email;
    if (email == null) return;
    await BiometricService.instance.saveCredentials(email, password);
    if (mounted) setState(() => _biometric = true);
  }

  Future<String?> _askPassword() {
    final ctrl = TextEditingController();
    bool obscure = true;
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Confirmer votre mot de passe',
                  style: AppText.h3(), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Votre mot de passe sera stocké de façon sécurisée pour la connexion biométrique.',
                style: AppText.body(color: textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: ctrl,
                obscureText: obscure,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: () => setLocal(() => obscure = !obscure),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, ctrl.text),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Activer la biométrie'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Annuler', style: AppText.body(color: textTertiary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? get _email =>
      Supabase.instance.client.auth.currentUser?.email;
  String? get _fullName => (Supabase.instance.client.auth.currentUser
          ?.userMetadata?['full_name'] as String?) ??
      _email;
  String? get _role => Supabase.instance.client.auth.currentUser
      ?.userMetadata?['role'] as String?;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceSecondary,
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: surfaceSecondary,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _accountHeader(),
          const SizedBox(height: 24),
          _section('Préférences', [
            _SettingTile(
              icon: Icons.notifications_outlined,
              iconColor: navyBlue,
              title: 'Notifications',
              trailing: Switch.adaptive(
                value: _notifications,
                activeThumbColor: navyBlue,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _notifications = v);
                },
              ),
            ),
            _SettingTile(
              icon: Icons.translate,
              iconColor: navyBlue,
              title: 'Langue',
              subtitle: _language,
              onTap: _openLanguageSheet,
            ),
            _SettingTile(
              icon: Icons.dark_mode_outlined,
              iconColor: navyBlue,
              title: 'Thème',
              subtitle: _theme,
              onTap: _openThemeSheet,
            ),
          ]),
          const SizedBox(height: 18),
          _section('Vérification & profil', [
            _SettingTile(
              icon: Icons.verified_user_outlined,
              iconColor: success,
              title: 'Vérification KYC',
              subtitle: 'Débloquer l\'escrow illimité',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KycFlowScreen()),
              ),
            ),
            if (_role == 'pme' || _role == null)
              _SettingTile(
                icon: Icons.business_outlined,
                iconColor: orange,
                title: 'Profil pro (PME)',
                subtitle: 'RCCM, NIF, certifications',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileCompletionScreen(),
                  ),
                ),
              ),
            _SettingTile(
              icon: Icons.edit_outlined,
              iconColor: mediumBlue,
              title: 'Modifier mon profil',
              subtitle: 'Nom, téléphone, photo',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EditProfileScreen(),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 18),
          _section('Sécurité', [
            _SettingTile(
              icon: Icons.lock_outline,
              iconColor: navyBlue,
              title: 'Changer mon mot de passe',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ForgotPasswordScreen(),
                ),
              ),
            ),
            _SettingTile(
              icon: Icons.fingerprint,
              iconColor: navyBlue,
              title: 'Authentification biométrique',
              subtitle: _bioAvailable
                  ? (_biometric ? 'Activée' : 'Désactivée')
                  : 'Non disponible sur cet appareil',
              trailing: Switch.adaptive(
                value: _biometric,
                activeThumbColor: navyBlue,
                onChanged: _bioAvailable ? _toggleBiometric : null,
              ),
            ),
          ]),
          const SizedBox(height: 18),
          _section('Support', [
            _SettingTile(
              icon: Icons.help_outline,
              iconColor: textTertiary,
              title: 'Aide & FAQ',
              onTap: () => _showNotImplemented('Aide & FAQ'),
            ),
            _SettingTile(
              icon: Icons.chat_bubble_outline,
              iconColor: textTertiary,
              title: 'Contacter le support',
              onTap: () => _showNotImplemented('Support'),
            ),
            _SettingTile(
              icon: Icons.description_outlined,
              iconColor: textTertiary,
              title: 'Conditions d\'utilisation',
              onTap: () => _showNotImplemented('CGU'),
            ),
            _SettingTile(
              icon: Icons.shield_outlined,
              iconColor: textTertiary,
              title: 'Politique de confidentialité',
              onTap: () => _showNotImplemented('Confidentialité'),
            ),
          ]),
          const SizedBox(height: 18),
          _section('Mode démo POESAM', [
            _SettingTile(
              icon: Icons.science_outlined,
              iconColor: orange,
              title: 'Fallback données mock',
              subtitle: 'Si le wifi tombe pendant le pitch',
              trailing: Switch.adaptive(
                value: _demoMode,
                activeThumbColor: orange,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _demoMode = v;
                    DemoConfig.kUseMockFallback = v;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        v
                            ? 'Mode démo activé — données mock'
                            : 'Mode démo désactivé — données live',
                      ),
                      backgroundColor: v ? orange : success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
          ]),
          const SizedBox(height: 18),
          _section('À propos', const [
            _SettingTile(
              icon: Icons.info_outline,
              iconColor: textTertiary,
              title: 'Version',
              subtitle: '1.0.0 (build 1)',
            ),
          ]),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Se déconnecter'),
            style: OutlinedButton.styleFrom(
              foregroundColor: danger,
              side: const BorderSide(color: danger),
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _confirmDeleteAccount,
            child: Text(
              'Supprimer mon compte',
              style: AppText.body(color: textTertiary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountHeader() {
    final name = _fullName ?? 'Utilisateur';
    final initials = _initials(name);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: navyBlue,
            child: Text(
              initials,
              style: AppText.h2(color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppText.h3()),
                const SizedBox(height: 4),
                if (_email != null)
                  Text(_email!,
                      style: AppText.caption(color: textTertiary)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: textTertiary.withValues(alpha: 0.6)),
        ],
      ),
    );
  }

  Widget _section(String label, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Text(label.toUpperCase(), style: AppText.micro()),
        ),
        Container(
          decoration: BoxDecoration(
            color: surfacePrimary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Column(
            children: [
              for (int i = 0; i < tiles.length; i++) ...[
                tiles[i],
                if (i < tiles.length - 1)
                  const Divider(height: 1, indent: 60, endIndent: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _openLanguageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _PickerSheet(
        title: 'Langue de l\'application',
        options: const <(String, IconData)>[
          ('Français', Icons.language),
          ('English', Icons.language),
          ('العربية', Icons.language),
          ('Wolof', Icons.language),
          ('Bamanankan', Icons.language),
        ],
        current: _language,
        onPick: (v) {
          HapticFeedback.selectionClick();
          setState(() => _language = v);
        },
      ),
    );
  }

  void _openThemeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _PickerSheet(
        title: 'Apparence',
        options: const <(String, IconData)>[
          ('Système', Icons.brightness_auto_outlined),
          ('Clair', Icons.light_mode_outlined),
          ('Sombre', Icons.dark_mode_outlined),
        ],
        current: _theme,
        onPick: (v) {
          HapticFeedback.selectionClick();
          setState(() => _theme = v);
        },
      ),
    );
  }

  Future<void> _confirmLogout() async {
    HapticFeedback.mediumImpact();
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
    await Supabase.instance.client.auth.signOut();
  }

  Future<void> _confirmDeleteAccount() async {
    HapticFeedback.heavyImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Supprimer mon compte'),
        content: const Text(
          'Cette action est définitive. Toutes vos données seront effacées sous 30 jours.\n\nVeuillez contacter le support pour confirmer la suppression.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: danger),
            child: const Text('Contacter le support'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _showNotImplemented('Suppression de compte');
  }

  void _showNotImplemented(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — bientôt disponible'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: navyBlue,
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.body(color: textPrimary)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppText.caption()),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ??
                (onTap != null
                    ? Icon(Icons.chevron_right,
                        color: textTertiary.withValues(alpha: 0.6))
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

class _PickerSheet extends StatelessWidget {
  final String title;
  final List<(String, IconData)> options;
  final String current;
  final ValueChanged<String> onPick;

  const _PickerSheet({
    required this.title,
    required this.options,
    required this.current,
    required this.onPick,
  });

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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(title, style: AppText.h3()),
            ),
            const SizedBox(height: 8),
            for (final o in options)
              ListTile(
                leading: Icon(o.$2, color: navyBlue, size: 20),
                title: Text(o.$1, style: AppText.body(color: textPrimary)),
                trailing: o.$1 == current
                    ? const Icon(Icons.check, color: navyBlue)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  onPick(o.$1);
                },
              ),
          ],
        ),
      ),
    );
  }
}
