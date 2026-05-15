import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import 'login_screen.dart';

/// Widget qui écoute l'état de l'authentification Supabase.
/// Redirige vers [TradeFlowApp] ou [LoginScreen] dynamiquement.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // En attente de la première réponse de Supabase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session;

        if (session != null) {
          // Utilisateur connecté
          // On retire le const car TradeFlowApp est un StatefulWidget complexe
          return const TradeFlowApp();
        } else {
          // Utilisateur non connecté
          return const LoginScreen();
        }
      },
    );
  }
}
