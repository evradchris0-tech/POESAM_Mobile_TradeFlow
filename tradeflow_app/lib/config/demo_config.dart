/// Configuration de la démo POESAM — TradeFlow Africa
///
/// Ce fichier contrôle le comportement de l'app en démo live.
///
/// USAGE NORMAL (Supabase actif) :
///   kUseMockFallback = false  ← ne pas toucher
///
/// URGENCE WIFI POESAM (si Supabase ne répond pas) :
///   → Passer kUseMockFallback = true dans ce fichier
///   → Hot reload (r minuscule dans le terminal Flutter)
///   → L'app bascule immédiatement sur les données mock
///   → Le jury ne voit rien, le pitch continue
///
/// APRÈS LA DÉMO :
///   → Remettre kUseMockFallback = false
class DemoConfig {
  DemoConfig._();

  /// Basculer sur true en cas de problème réseau pendant la démo.
  /// Le reste de l'app s'adapte automatiquement.
  static bool kUseMockFallback = false;

  /// Timeout Supabase en secondes.
  /// Au-delà, l'app affiche "Connexion lente" et tombe sur le fallback.
  static const int kTimeoutSeconds = 8;

  /// Message affiché quand le timeout est atteint.
  static const String kTimeoutMessage =
      'Connexion lente. Affichage en mode hors-ligne.';
}
