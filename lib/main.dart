import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/ad_service.dart';
import 'services/database_service.dart';
import 'services/platform_support.dart';
import 'services/revenue_cat_service.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/calculator_screen.dart';

// Keys for SharedPreferences
const String kPrefIsFirstLaunch = 'isFirstLaunch';
const String kPrefSelectedRegion = 'selectedRegion';
const String kPrefSelectedStandard = 'selectedStandard';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientation is left unrestricted so tablets, foldables and Chromebooks
  // get the large-screen experience required by Play quality guidelines.
  if (PlatformSupport.isMobile) {
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  // Style Android system navigation and status bars for Dark Theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF121417),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final bool isFirstLaunch = prefs.getBool(kPrefIsFirstLaunch) ?? true;

  // Initialize AdMob SDK in background
  try {
    if (PlatformSupport.supportsAds) {
      await MobileAds.instance.initialize();
      await AdService.instance.preloadAds();
    }
  } catch (e) {
    debugPrint('AdMob Initialization warning: $e');
  }

  // Initialize RevenueCat SDK
  try {
    await RevenueCatService.instance.initialize();
  } catch (e) {
    debugPrint('RevenueCat Initialization warning: $e');
  }

  // Initialize Local SQLite Database for Offline Reference Tables
  try {
    if (PlatformSupport.supportsSqlite) {
      await DatabaseService.instance.initDatabase();
    }
  } catch (e) {
    debugPrint('Database Initialization warning: $e');
  }

  runApp(
    ProviderScope(
      child: HvacCalculatorApp(isFirstLaunch: isFirstLaunch),
    ),
  );
}

class HvacCalculatorApp extends StatelessWidget {
  final bool isFirstLaunch;

  const HvacCalculatorApp({super.key, required this.isFirstLaunch});

  @override
  Widget build(BuildContext context) {
    // Material 3 Dark Baseline Theme tailored for technicians
    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F1216),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF10B981), // Emerald 500
        onPrimary: Color(0xFF003822),
        primaryContainer: Color(0xFF064E3B),
        onPrimaryContainer: Color(0xFF6EE7B7),
        secondary: Color(0xFF06B6D4), // Cyan 500
        onSecondary: Color(0xFF00363F),
        surface: Color(0xFF171B21),
        onSurface: Color(0xFFE2E8F0),
        surfaceContainerHighest: Color(0xFF222831),
        error: Color(0xFFEF4444),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF171B21),
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFF2A323D), width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1C222B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2D3748)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2D3748)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
      ),
    );

    return MaterialApp(
      title: 'HVAC Duct Sizing & Airflow Calculator',
      debugShowCheckedModeBanner: false,
      theme: darkTheme,
      home: isFirstLaunch
          ? const OnboardingWizardScreen()
          : const CalculatorScreen(),
    );
  }
}
