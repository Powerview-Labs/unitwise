import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'config/theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/otp_verification_screen.dart';
import 'screens/password_setup_screen.dart';
import 'screens/location_setup_screen.dart';
import 'screens/estimator/appliance_estimator_screen.dart';
import 'screens/appliance_estimator_prompt_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/dashboard/services/dashboard_service.dart';
// Token Logger imports
import 'features/token_logger/screens/token_entry_screen.dart';
import 'features/token_logger/providers/token_logger_provider.dart';
// Budget Planner imports
import 'features/budget_planner/providers/budget_planner_provider.dart';
import 'features/budget_planner/budget_planner_navigator.dart';
import 'features/budget_planner/screens/saved_plans_screen.dart';
// Token History imports
import 'features/token_history/providers/token_history_provider.dart';
import 'features/token_history/services/token_history_service.dart';
import 'features/token_history/screens/token_history_screen.dart';
// ⭐ MODULE 8: Settings imports
import 'features/settings/providers/settings_provider.dart';
import 'features/settings/services/settings_service.dart';
import 'features/settings/screens/settings_screen.dart';
// Main Scaffold with Bottom Navigation
import 'screens/main_scaffold.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'services/storage_service.dart';
import 'services/appliance_service.dart';
import 'services/band_lookup_service.dart';
import 'services/location_service.dart';
import 'controllers/estimator/appliance_estimator_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final storageService = StorageService();
  await storageService.initialize();

  // ✅ PRODUCTION MODE: Emulator disabled for Play Store deployment
  // Firebase Phone Auth will send REAL SMS to REAL phone numbers
  // if (kDebugMode) {
  //   await FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099);
  //   FirebaseFirestore.instance.useFirestoreEmulator('10.0.2.2', 8080);
  // }

  runApp(UnitWiseApp(storageService: storageService));
}

class UnitWiseApp extends StatelessWidget {
  final StorageService storageService;
  const UnitWiseApp({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<StorageService>.value(value: storageService),
        Provider<UserService>(create: (_) => UserService()),
        Provider<LocationService>(create: (_) => LocationService()),
        Provider<ApplianceService>(create: (_) => ApplianceService()),
        Provider<BandLookupService>(create: (_) => FirestoreBandLookupService()),
        ProxyProvider<StorageService, DashboardService>(
          update: (context, storage, _) => DashboardService(storageService: storage),
        ),
        ChangeNotifierProxyProvider<DashboardService, DashboardProvider?>(
          create: (context) {
            final userId = FirebaseAuth.instance.currentUser?.uid;
            if (userId == null) return null;
            return DashboardProvider(dashboardService: context.read<DashboardService>(), userId: userId);
          },
          update: (context, service, previous) {
            final userId = FirebaseAuth.instance.currentUser?.uid;
            if (userId == null) return null;
            if (previous == null) return DashboardProvider(dashboardService: service, userId: userId);
            return previous;
          },
        ),
        ChangeNotifierProvider<ApplianceEstimatorController>(create: (_) => ApplianceEstimatorController()),

        // Token Logger Provider
        ChangeNotifierProvider<TokenLoggerProvider>(
          create: (_) => TokenLoggerProvider(),
        ),

        // Budget Planner Provider
        ChangeNotifierProvider<BudgetPlannerProvider>(
          create: (_) => BudgetPlannerProvider(),
        ),

        // Token History Provider
        ChangeNotifierProvider<TokenHistoryProvider>(
          create: (_) => TokenHistoryProvider(
            TokenHistoryService(),
          ),
        ),

        // ⭐ MODULE 8: Settings Provider
        // Creates SettingsProvider only when user is authenticated
        ChangeNotifierProxyProvider0<SettingsProvider?>(
          create: (context) {
            final userId = FirebaseAuth.instance.currentUser?.uid;
            if (userId == null) return null;
            return SettingsProvider(
              settingsService: SettingsService(userId: userId),
            );
          },
          update: (context, previous) {
            final userId = FirebaseAuth.instance.currentUser?.uid;
            if (userId == null) return null;

            // If provider already exists for this user, keep it
            if (previous != null) return previous;

            // Create new provider for newly authenticated user
            return SettingsProvider(
              settingsService: SettingsService(userId: userId),
            );
          },
        ),
      ],
      child: const _UnitWiseAppContent(),
    );
  }
}

/// ⭐ NEW: Separate widget to watch Settings and apply theme
/// This allows theme changes to take effect immediately
class _UnitWiseAppContent extends StatelessWidget {
  const _UnitWiseAppContent();

  @override
  Widget build(BuildContext context) {
    // Watch SettingsProvider for theme changes
    final settingsProvider = context.watch<SettingsProvider?>();
    final themeMode = _getThemeMode(settingsProvider?.settings?.theme);

    return MaterialApp(
      title: 'UnitWise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/signup': (context) => const SignupScreen(),
        '/login': (context) => const LoginScreen(),
        '/appliance-estimator-prompt': (context) => const ApplianceEstimatorPromptScreen(),
        '/appliance-estimator': (context) => const ApplianceEstimatorScreen(),
        '/dashboard': (context) => const MainScaffold(initialIndex: 0),
        '/token-logger': (context) => const TokenEntryScreen(),
        '/budget-planner': (context) => const BudgetPlannerNavigator(),
        '/saved-plans': (context) => const SavedPlansScreen(),
        '/token-history': (context) => const TokenHistoryScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      onGenerateRoute: (settings) {
        final args = settings.arguments as Map<String, dynamic>?;
        switch (settings.name) {
          case '/verify-otp':
            return MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                phoneNumber: args?['phoneNumber'] ?? '',
                sessionId: args?['sessionId'] ?? '',
                name: args?['name'] ?? '',
                email: args?['email'] ?? '',
                isLogin: args?['isLogin'] ?? false, // ✅ isLogin flag added
              ),
            );
          case '/password-setup':
            return MaterialPageRoute(
              builder: (context) => PasswordSetupScreen(
                phoneNumber: args?['phoneNumber'] ?? '',
                name: args?['name'] ?? '',
                email: args?['email'] ?? '',
              ),
            );
          case '/location-setup':
            return MaterialPageRoute(
              builder: (context) => LocationSetupScreen(
                phoneNumber: args?['phoneNumber'] ?? '',
                name: args?['name'] ?? '',
                email: args?['email'] ?? '',
              ),
            );
          default:
            return null;
        }
      },
    );
  }

  /// Convert settings theme string to ThemeMode
  ThemeMode _getThemeMode(String? theme) {
    switch (theme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}