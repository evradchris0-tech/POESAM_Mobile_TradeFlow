import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;
  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  static const int _otpLength = 8;
  final List<TextEditingController> _controllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_otpLength, (_) => FocusNode());
  bool _loading = false;

  Future<void> _verify() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length < _otpLength) return;

    setState(() => _loading = true);
    try {
      // Verification par Email OTP. Supabase cree automatiquement une session
      // si l'OTP est valide.
      await Supabase.instance.client.auth.verifyOTP(
        email: widget.email,
        token: code,
        type: OtpType.signup,
      );

      // On tue immediatement cette session pour forcer l'utilisateur a se
      // connecter manuellement avec ses identifiants. Cela valide d'un coup
      // que :
      //   - le compte est bien cree
      //   - le mot de passe choisi fonctionne
      //   - le chemin login (= chemin logout/relogin) est operationnel
      await Supabase.instance.client.auth.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compte créé. Connectez-vous avec vos identifiants.'),
            backgroundColor: success,
          ),
        );
        // AuthWrapper detecte l'absence de session et affiche LoginScreen.
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Code email invalide ou expiré');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: danger, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfacePrimary,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Vérification Email', style: AppText.h1()),
              const SizedBox(height: 8),
              Text(
                'Entrez le code reçu par email à ${widget.email}',
                style: AppText.body(color: textTertiary),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  for (int i = 0; i < _otpLength; i++) ...[
                    Expanded(child: _otpBox(i)),
                    if (i < _otpLength - 1) const SizedBox(width: 6),
                  ],
                ],
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _loading ? null : _verify,
                child: _loading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Activer mon compte'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () { /* Resend Email */ },
                child: Text('Renvoyer l\'email', style: AppText.body(color: navyBlue, weight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _otpBox(int index) {
    return TextField(
      controller: _controllers[index],
      focusNode: _focusNodes[index],
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 1,
      style: AppText.h2(color: navyBlue),
      decoration: const InputDecoration(
        counterText: "",
        contentPadding: EdgeInsets.zero,
      ),
      onChanged: (value) {
        if (value.isNotEmpty && index < _otpLength - 1) {
          _focusNodes[index + 1].requestFocus();
        } else if (value.isEmpty && index > 0) {
          _focusNodes[index - 1].requestFocus();
        }
        if (_controllers.every((c) => c.text.isNotEmpty)) _verify();
      },
    );
  }
}
