import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/biometric_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_logo.dart';
import '../onboarding_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading  = false;
  bool _obscure  = true;

  bool     _bioAvailable = false;
  bool     _bioEnabled   = false;
  IconData _bioIcon      = Icons.fingerprint;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final available = await BiometricService.instance.isAvailable();
    final enabled   = await BiometricService.instance.isEnabled();
    final icon      = await BiometricService.instance.icon();
    if (!mounted) return;
    setState(() {
      _bioAvailable = available;
      _bioEnabled   = enabled;
      _bioIcon      = icon;
    });
  }

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      _showError('Veuillez remplir tous les champs');
      return;
    }
    setState(() => _loading = true);
    try {
      final email    = _emailCtrl.text.trim();
      final password = _passCtrl.text;
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (_bioAvailable && !_bioEnabled && mounted) {
        await _offerBiometric(email, password);
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Une erreur inattendue est survenue');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithBiometrics() async {
    setState(() => _loading = true);
    try {
      final authenticated = await BiometricService.instance.authenticate();
      if (!authenticated) { setState(() => _loading = false); return; }
      final creds = await BiometricService.instance.getCredentials();
      if (creds == null) {
        _showError('Identifiants introuvables. Reconnectez-vous manuellement.');
        setState(() => _loading = false);
        return;
      }
      await Supabase.instance.client.auth.signInWithPassword(
        email: creds.$1,
        password: creds.$2,
      );
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Authentification biométrique échouée');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _offerBiometric(String email, String password) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BiometricOfferSheet(
        icon: _bioIcon,
        label: 'Empreinte digitale',
        onEnable: () async {
          await BiometricService.instance.saveCredentials(email, password);
          if (mounted) setState(() => _bioEnabled = true);
        },
      ),
    );
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
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final heroH = (MediaQuery.of(context).size.height * 0.34).clamp(200.0, 280.0);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Gradient background (full screen)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D2444), navyBlue, mediumBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // Geometric overlay
          Positioned.fill(
            child: CustomPaint(painter: _LoginGeometry()),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // ── Hero section ─────────────────────────────────────
                SizedBox(
                  height: heroH,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 8, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Help button aligned right
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.help_outline,
                                color: Colors.white60, size: 22),
                            tooltip: 'Découvrir TradeFlow',
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const OnboardingScreen()),
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Logo (blanc via filtre couleur)
                        ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                              Colors.white, BlendMode.srcIn),
                          child: const BrandLogoFull(height: 38),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Commerce transfrontalier\nde confiance',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Pill badges
                        Row(
                          children: [
                            _HeroPill('PAPSS'),
                            const SizedBox(width: 8),
                            _HeroPill('AGL Logistics'),
                            const SizedBox(width: 8),
                            _HeroPill('7 pays'),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),

                // ── Form card ────────────────────────────────────────
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: surfacePrimary,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(28)),
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                        child: _buildForm(),
                      ),
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

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Drag handle
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
        const SizedBox(height: 20),

        Text('Connexion', style: AppText.h2()),
        const SizedBox(height: 4),
        Text(
          'Accédez à votre espace exportateur',
          style: AppText.caption(),
        ),
        const SizedBox(height: 28),

        // Email
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'Email professionnel',
            prefixIcon: Icon(Icons.email_outlined, size: 20),
          ),
        ),
        const SizedBox(height: 14),

        // Password
        TextField(
          controller: _passCtrl,
          obscureText: _obscure,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _login(),
          decoration: InputDecoration(
            hintText: 'Mot de passe',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off : Icons.visibility,
                size: 20,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 4),

        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
            child: Text('Mot de passe oublié ?',
                style: AppText.caption(color: navyBlue)),
          ),
        ),
        const SizedBox(height: 20),

        // Primary CTA — gradient
        _GradientButton(
          onPressed: _loading ? null : _login,
          loading: _loading,
          label: 'Se connecter',
        ),

        // Biometric
        if (_bioAvailable && _bioEnabled) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loading ? null : _loginWithBiometrics,
            icon: Icon(_bioIcon, size: 18),
            label: const Text('Continuer avec la biométrie'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: navyBlue,
              side: const BorderSide(color: navyBlue, width: 1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],

        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Pas encore de compte ?', style: AppText.body()),
            TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen())),
              child: Text(
                'Créer un compte',
                style: AppText.body(color: orange, weight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Pill hero ───────────────────────────────────────────────────────────────

class _HeroPill extends StatelessWidget {
  final String label;
  const _HeroPill(this.label);

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

// ── Gradient CTA button ─────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;
  final String label;

  const _GradientButton({
    required this.onPressed,
    required this.loading,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: enabled
            ? const LinearGradient(
                colors: [navyBlue, mediumBlue],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: enabled ? null : Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: navyBlue.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Geometric background painter ────────────────────────────────────────────

class _LoginGeometry extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ring = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Rings top-right
    canvas.drawCircle(Offset(size.width + 16, -24), 170, ring);
    canvas.drawCircle(Offset(size.width + 16, -24), 115, ring);
    canvas.drawCircle(Offset(size.width + 16, -24), 66,  ring);

    // Filled blob bottom-left
    canvas.drawCircle(
      Offset(-28, size.height * 0.30),
      84,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.04)
        ..style = PaintingStyle.fill,
    );

    // Dot cluster mid-left
    final dot = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;
    for (final o in [
      Offset(size.width * 0.12, size.height * 0.24),
      Offset(size.width * 0.20, size.height * 0.30),
      Offset(size.width * 0.07, size.height * 0.33),
      Offset(size.width * 0.16, size.height * 0.38),
    ]) {
      canvas.drawCircle(o, 2.5, dot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Bottom sheet biometric offer ────────────────────────────────────────────

class _BiometricOfferSheet extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onEnable;

  const _BiometricOfferSheet({
    required this.icon,
    required this.label,
    required this.onEnable,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: navyBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: navyBlue),
            ),
            const SizedBox(height: 16),
            Text('Activer la connexion biométrique',
                style: AppText.h2(), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Connectez-vous plus rapidement à TradeFlow grâce à votre $label.',
              style: AppText.body(color: textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(icon, size: 18),
                label: const Text('Activer'),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () {
                  Navigator.pop(context);
                  onEnable();
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Plus tard',
                    style: AppText.body(color: textTertiary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
