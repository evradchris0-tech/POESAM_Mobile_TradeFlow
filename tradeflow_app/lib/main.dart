import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'theme/app_theme.dart';
import 'widgets/bottom_nav.dart';
import 'screens/home_screen.dart';
import 'screens/market_screen.dart';
import 'screens/customs_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/transaction_history_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Fichier .env non trouvé. Assurez-vous d'en créer un à la racine.");
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  runApp(const TradeFlowRoot());
}

/// Raccourci global pour acceder au client Supabase partout dans l'app.
/// Usage : `await supabase.from('profiles').select()`
final supabase = Supabase.instance.client;

class TradeFlowRoot extends StatelessWidget {
  const TradeFlowRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TradeFlow Africa',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      home: const SplashScreen(next: AuthWrapper()),
    );
  }
}

class TradeFlowApp extends StatefulWidget {
  const TradeFlowApp({super.key});

  @override
  State<TradeFlowApp> createState() => _TradeFlowAppState();
}

class _TradeFlowAppState extends State<TradeFlowApp> {
  int _currentIndex = 0;

  void _goTo(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final role = supabase.auth.currentUser?.userMetadata?['role'] as String? ?? 'pme';

    final screens = <Widget>[
      HomeScreen(onNavigate: _goTo),
      if (role == 'pme' || role == 'buyer') MarketScreen(onNavigate: _goTo)
      else if (role == 'customs') const Scaffold(body: Center(child: Text("Inspections Douanières (Bientôt)")))
      else const Scaffold(body: Center(child: Text("Fret et Cargaisons (Bientôt)"))),
      CustomsScreen(onNavigate: _goTo),
      const TransactionHistoryScreen(),
      ProfileScreen(onNavigate: _goTo),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        role: role,
        onTap: _goTo,
      ),
    );
  }
}
