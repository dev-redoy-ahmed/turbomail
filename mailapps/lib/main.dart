import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'providers/email_provider.dart';
import 'providers/premium_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/splash_screen.dart';
import 'services/ads_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Mobile Ads SDK first (skip on web)
  if (!kIsWeb) {
    debugPrint('Initializing Mobile Ads SDK...');
    await MobileAds.instance.initialize();
    debugPrint('Mobile Ads SDK initialized');
  } else {
    debugPrint('Skipping Mobile Ads SDK initialization on web platform');
  }
  
  // Create and initialize Ads Service
  final adsService = AdsService();
  await adsService.initialize();
  
  // Create EmailProvider instance (it will handle auto-generation internally)
  final emailProvider = EmailProvider();
  
  runApp(TurboMailApp(
    emailProvider: emailProvider,
    adsService: adsService,
  ));
}

class TurboMailApp extends StatefulWidget {
  final EmailProvider emailProvider;
  final AdsService adsService;
  
  const TurboMailApp({
    super.key, 
    required this.emailProvider,
    required this.adsService,
  });

  @override
  State<TurboMailApp> createState() => _TurboMailAppState();
}

class _TurboMailAppState extends State<TurboMailApp> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Clear cache when app is paused, detached, or hidden
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      debugPrint('App lifecycle changed to: $state - Clearing ad cache');
      widget.adsService.clearAdCache();
    }
  }
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.emailProvider),
        ChangeNotifierProvider(create: (_) => PremiumProvider()),
        Provider.value(value: widget.adsService),
      ],
      child: MaterialApp(
        title: 'TurboMail',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF1A2434),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00D4AA),
            secondary: Color(0xFF1DB584),
            surface: Color(0xFF1A2434),
            background: Color(0xFF1A2434),
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: Colors.white,
            onBackground: Colors.white,
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFF1A2434),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4AA),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF1A2434),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00D4AA)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00D4AA), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00D4AA), width: 2),
            ),
            labelStyle: const TextStyle(color: Colors.white70),
            hintStyle: const TextStyle(color: Colors.white54),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1A2434),
            elevation: 0,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF1A2434),
            selectedItemColor: Color(0xFF00D4AA),
            unselectedItemColor: Colors.white54,
            type: BottomNavigationBarType.fixed,
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
