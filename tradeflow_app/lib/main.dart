import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme/app_theme.dart';
import 'widgets/bottom_nav.dart';
import 'screens/home_screen.dart';
import 'screens/market_screen.dart';
import 'screens/customs_screen.dart';
import 'screens/escrow_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  runApp(const TradeFlowRoot());
}

class TradeFlowRoot extends StatelessWidget {
  const TradeFlowRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TradeFlow Africa',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      home: const SplashScreen(next: TradeFlowApp()),
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
    final screens = <Widget>[
      HomeScreen(onNavigate: _goTo),
      MarketScreen(onNavigate: _goTo),
      CustomsScreen(onNavigate: _goTo),
      EscrowScreen(onNavigate: _goTo),
      ProfileScreen(onNavigate: _goTo),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: _goTo,
      ),
    );
  }
}
