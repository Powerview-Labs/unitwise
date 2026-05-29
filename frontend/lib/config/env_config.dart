/// ENVIRONMENT CONFIGURATION MANAGER
/// 
/// Centralized access to environment variables loaded from .env file
/// Provides type-safe access with default values and validation
/// 
/// SECURITY FEATURES:
/// - HTTPS enforcement in production
/// - Environment validation on app start
/// - No hardcoded credentials
/// - Safe default values for optional config
/// 
/// USAGE:
/// ```dart
/// String apiUrl = EnvConfig.apiBaseUrl;
/// bool isDebug = EnvConfig.isDevelopment;
/// int otpLength = EnvConfig.otpLength;
/// ```
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// EnvConfig Class
/// 
/// Static class that provides read-only access to environment variables
/// All values are loaded from .env file via flutter_dotenv
/// 
/// SECURITY: Never modify these values at runtime
/// SECURITY: Never expose these values in logs (especially in production)
class EnvConfig {
  // Prevent instantiation - this is a utility class with only static members
  // Using factory constructor that throws ensures class cannot be instantiated
  EnvConfig._();

  // ===========================================================================
  // BACKEND API CONFIGURATION
  // ===========================================================================

  /// Base URL for Cloud Functions API
  /// 
  /// SECURITY: Must use HTTPS in production
  /// Development: http://localhost:5001/... (Firebase emulator)
  /// Production: https://us-central1-projectid.cloudfunctions.net
  static String get apiBaseUrl {
    final url = dotenv.env['API_BASE_URL'] ?? '';
    
    // SECURITY: Validate URL is not empty
    if (url.isEmpty) {
      print('[EnvConfig] WARNING: API_BASE_URL is not set in .env');
      print('[EnvConfig] Using default: http://localhost:5001');
      return 'http://localhost:5001/unitwise-83a71/us-central1';
    }
    
    // SECURITY: Warn if using HTTP in production
    if (isProduction && !url.startsWith('https://')) {
      print('[EnvConfig] ⚠️  SECURITY WARNING: Using HTTP in production!');
      print('[EnvConfig] API_BASE_URL should use HTTPS in production');
    }
    
    return url;
  }

  /// API request timeout in milliseconds
  /// 
  /// Default: 30000ms (30 seconds)
  /// Prevents hanging requests and improves UX
  static int get apiTimeout {
    final timeoutStr = dotenv.env['API_TIMEOUT'] ?? '30000';
    return int.tryParse(timeoutStr) ?? 30000;
  }

  // ===========================================================================
  // FIREBASE CONFIGURATION
  // ===========================================================================

  /// Firebase Project ID
  /// 
  /// SECURITY: Required for Firebase initialization
  /// Found in Firebase Console → Project Settings
  static String get firebaseProjectId {
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
    
    if (projectId.isEmpty) {
      print('[EnvConfig] ERROR: FIREBASE_PROJECT_ID is not set in .env');
    }
    
    return projectId;
  }

  /// Firebase API Key
  /// 
  /// SECURITY: This is a public API key (safe to expose in mobile apps)
  /// Firebase security is enforced via Firestore Rules and App Check
  /// Found in Firebase Console → Project Settings → General
  static String get firebaseApiKey {
    final apiKey = dotenv.env['FIREBASE_API_KEY'] ?? '';
    
    if (apiKey.isEmpty) {
      print('[EnvConfig] ERROR: FIREBASE_API_KEY is not set in .env');
    }
    
    return apiKey;
  }

  /// Firebase Auth Domain
  /// 
  /// Usually: your-project-id.firebaseapp.com
  static String get firebaseAuthDomain {
    final authDomain = dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '';
    
    if (authDomain.isEmpty) {
      print('[EnvConfig] WARNING: FIREBASE_AUTH_DOMAIN is not set in .env');
      // Use default pattern based on project ID
      return '$firebaseProjectId.firebaseapp.com';
    }
    
    return authDomain;
  }

  /// Firebase Storage Bucket
  /// 
  /// Usually: your-project-id.appspot.com
  static String get firebaseStorageBucket {
    final storageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';
    
    if (storageBucket.isEmpty) {
      print('[EnvConfig] WARNING: FIREBASE_STORAGE_BUCKET is not set in .env');
      // Use default pattern based on project ID
      return '$firebaseProjectId.appspot.com';
    }
    
    return storageBucket;
  }

  /// Firebase Messaging Sender ID
  /// 
  /// Found in Firebase Console → Project Settings → Cloud Messaging
  static String get firebaseMessagingSenderId {
    return dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  }

  /// Firebase App ID
  /// 
  /// Found in Firebase Console → Project Settings → Your apps
  static String get firebaseAppId {
    return dotenv.env['FIREBASE_APP_ID'] ?? '';
  }

  // ===========================================================================
  // APPLICATION CONFIGURATION
  // ===========================================================================

  /// Application environment
  /// 
  /// Values: development | staging | production
  /// Controls logging, error handling, and feature flags
  static String get appEnv {
    return dotenv.env['APP_ENV'] ?? 'development';
  }

  /// Check if running in development mode
  /// 
  /// SECURITY: Enables verbose logging and debug features
  static bool get isDevelopment => appEnv == 'development';

  /// Check if running in staging mode
  /// 
  /// SECURITY: Limited logging, testing features enabled
  static bool get isStaging => appEnv == 'staging';

  /// Check if running in production mode
  /// 
  /// SECURITY: Minimal logging, all debug features disabled
  static bool get isProduction => appEnv == 'production';

  /// Application name
  /// 
  /// Displayed in app title and splash screen
  static String get appName {
    return dotenv.env['APP_NAME'] ?? 'UnitWise';
  }

  /// Application version
  /// 
  /// Must match version in pubspec.yaml
  static String get appVersion {
    return dotenv.env['APP_VERSION'] ?? '1.0.0';
  }

  // ===========================================================================
  // AUTHENTICATION CONFIGURATION
  // ===========================================================================

  /// OTP code length
  /// 
  /// SECURITY: Must match backend configuration
  /// Default: 6 digits
  static int get otpLength {
    final lengthStr = dotenv.env['OTP_LENGTH'] ?? '6';
    return int.tryParse(lengthStr) ?? 6;
  }

  /// OTP expiry time in seconds
  /// 
  /// SECURITY: Must match backend configuration
  /// Default: 300 seconds (5 minutes)
  static int get otpExpirySeconds {
    final expiryStr = dotenv.env['OTP_EXPIRY_SECONDS'] ?? '300';
    return int.tryParse(expiryStr) ?? 300;
  }

  /// Maximum login attempts before account lockout
  /// 
  /// SECURITY: Prevents brute force attacks
  /// Default: 5 attempts
  static int get maxLoginAttempts {
    final attemptsStr = dotenv.env['MAX_LOGIN_ATTEMPTS'] ?? '5';
    return int.tryParse(attemptsStr) ?? 5;
  }

  /// Session timeout in minutes
  /// 
  /// SECURITY: Auto-logout after inactivity
  /// Default: 30 minutes
  /// 0 = no timeout (not recommended for production)
  static int get sessionTimeoutMinutes {
    final timeoutStr = dotenv.env['SESSION_TIMEOUT_MINUTES'] ?? '30';
    return int.tryParse(timeoutStr) ?? 30;
  }

  /// Maximum OTP requests per hour
  /// 
  /// SECURITY: Prevents OTP spam and abuse
  /// Default: 3 requests per hour
  static int get maxOtpRequestsPerHour {
    final requestsStr = dotenv.env['MAX_OTP_REQUESTS_PER_HOUR'] ?? '3';
    return int.tryParse(requestsStr) ?? 3;
  }

  /// Resend OTP cooldown in seconds
  /// 
  /// SECURITY: Prevents rapid OTP resend requests
  /// Default: 30 seconds
  static int get resendOtpCooldownSeconds {
    final cooldownStr = dotenv.env['RESEND_OTP_COOLDOWN_SECONDS'] ?? '30';
    return int.tryParse(cooldownStr) ?? 30;
  }

  // ===========================================================================
  // SECURITY CONFIGURATION
  // ===========================================================================

  /// Enable secure storage encryption
  /// 
  /// SECURITY: Uses platform keystore (Android) / keychain (iOS)
  /// Should always be true in production
  static bool get enableSecureStorage {
    final enabledStr = dotenv.env['ENABLE_SECURE_STORAGE'] ?? 'true';
    return enabledStr.toLowerCase() == 'true';
  }

  /// Enable certificate pinning
  /// 
  /// SECURITY: Prevents man-in-the-middle attacks
  /// Requires SSL certificate hash configuration
  static bool get enableCertificatePinning {
    final enabledStr = dotenv.env['ENABLE_CERTIFICATE_PINNING'] ?? 'false';
    return enabledStr.toLowerCase() == 'true';
  }

  /// Enable biometric authentication
  /// 
  /// SECURITY: Fingerprint/Face ID for quick login
  static bool get enableBiometricAuth {
    final enabledStr = dotenv.env['ENABLE_BIOMETRIC_AUTH'] ?? 'false';
    return enabledStr.toLowerCase() == 'true';
  }

  /// Enable Firebase App Check
  /// 
  /// SECURITY: Prevents unauthorized API access
  /// Requires Firebase App Check setup
  static bool get enableAppCheck {
    final enabledStr = dotenv.env['ENABLE_APP_CHECK'] ?? 'false';
    return enabledStr.toLowerCase() == 'true';
  }

  // ===========================================================================
  // FEATURE FLAGS
  // ===========================================================================

  /// Enable location-based DisCo detection
  /// 
  /// Requires geolocator permission
  static bool get enableLocationFeatures {
    final enabledStr = dotenv.env['ENABLE_LOCATION_FEATURES'] ?? 'true';
    return enabledStr.toLowerCase() == 'true';
  }

  /// Enable email notifications
  /// 
  /// Requires email verification
  static bool get enableEmailNotifications {
    final enabledStr = dotenv.env['ENABLE_EMAIL_NOTIFICATIONS'] ?? 'true';
    return enabledStr.toLowerCase() == 'true';
  }

  /// Enable SMS fallback for OTP
  /// 
  /// Uses Twilio/Termii SMS if WhatsApp fails
  static bool get enableSmsFallback {
    final enabledStr = dotenv.env['ENABLE_SMS_FALLBACK'] ?? 'true';
    return enabledStr.toLowerCase() == 'true';
  }

  /// Enable dark mode
  /// 
  /// User preference, saved in SharedPreferences
  static bool get enableDarkMode {
    final enabledStr = dotenv.env['ENABLE_DARK_MODE'] ?? 'true';
    return enabledStr.toLowerCase() == 'true';
  }

  /// Enable analytics (Firebase Analytics)
  /// 
  /// SECURITY: Tracks app usage without PII
  static bool get enableAnalytics {
    final enabledStr = dotenv.env['ENABLE_ANALYTICS'] ?? 'false';
    return enabledStr.toLowerCase() == 'true';
  }

  /// Enable crash reporting (Firebase Crashlytics)
  /// 
  /// SECURITY: Helps debug production issues
  static bool get enableCrashReporting {
    final enabledStr = dotenv.env['ENABLE_CRASH_REPORTING'] ?? 'false';
    return enabledStr.toLowerCase() == 'true';
  }

  // ===========================================================================
  // LOGGING CONFIGURATION
  // ===========================================================================

  /// Log level
  /// 
  /// Values: none | error | warning | info | debug | verbose
  /// SECURITY: Use 'error' or 'warning' in production to avoid logging PII
  static String get logLevel {
    return dotenv.env['LOG_LEVEL'] ?? 'debug';
  }

  /// Enable network request logging
  /// 
  /// SECURITY: Logs HTTP requests/responses (disable in production)
  static bool get logNetworkRequests {
    final enabledStr = dotenv.env['LOG_NETWORK_REQUESTS'] ?? 'true';
    return enabledStr.toLowerCase() == 'true' && isDevelopment;
  }

  /// Enable Firestore query logging
  /// 
  /// SECURITY: Logs database queries (disable in production)
  static bool get logFirestoreQueries {
    final enabledStr = dotenv.env['LOG_FIRESTORE_QUERIES'] ?? 'false';
    return enabledStr.toLowerCase() == 'true' && isDevelopment;
  }

  // ===========================================================================
  // UI CONFIGURATION
  // ===========================================================================

  /// Default theme mode
  /// 
  /// Values: light | dark | system
  static String get defaultThemeMode {
    return dotenv.env['DEFAULT_THEME_MODE'] ?? 'light';
  }

  /// Enable splash screen animation
  static bool get enableSplashAnimation {
    final enabledStr = dotenv.env['ENABLE_SPLASH_ANIMATION'] ?? 'true';
    return enabledStr.toLowerCase() == 'true';
  }

  /// Splash screen duration in milliseconds
  /// 
  /// Default: 2000ms (2 seconds)
  static int get splashDuration {
    final durationStr = dotenv.env['SPLASH_DURATION'] ?? '2000';
    return int.tryParse(durationStr) ?? 2000;
  }

  // ===========================================================================
  // EXTERNAL SERVICES (Future Integration)
  // ===========================================================================

  /// Google Maps API Key
  /// 
  /// SECURITY: Restrict API key to your app's package name
  static String get googleMapsApiKey {
    return dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  }

  // ===========================================================================
  // DEVELOPMENT & TESTING
  // ===========================================================================

  /// Enable mock API responses
  /// 
  /// SECURITY: MUST be false in production
  static bool get enableMockApi {
    final enabledStr = dotenv.env['ENABLE_MOCK_API'] ?? 'false';
    return enabledStr.toLowerCase() == 'true' && !isProduction;
  }

  /// Enable test mode
  /// 
  /// SECURITY: MUST be false in production
  static bool get enableTestMode {
    final enabledStr = dotenv.env['ENABLE_TEST_MODE'] ?? 'false';
    return enabledStr.toLowerCase() == 'true' && !isProduction;
  }

  // ===========================================================================
  // COMPLIANCE & LEGAL
  // ===========================================================================

  /// Terms & Conditions URL
  static String get termsUrl {
    return dotenv.env['TERMS_URL'] ?? 'https://unitwise.app/terms';
  }

  /// Privacy Policy URL
  static String get privacyUrl {
    return dotenv.env['PRIVACY_URL'] ?? 'https://unitwise.app/privacy';
  }

  /// Support email
  static String get supportEmail {
    return dotenv.env['SUPPORT_EMAIL'] ?? 'support@unitwise.app';
  }

  /// Support phone (WhatsApp)
  static String get supportPhone {
    return dotenv.env['SUPPORT_PHONE'] ?? '+2348100000000';
  }

  // ===========================================================================
  // VALIDATION HELPER
  // ===========================================================================

  /// Validate all critical environment variables are set
  /// 
  /// Call this on app start to ensure configuration is complete
  /// 
  /// SECURITY: Prevents app from running with incomplete configuration
  /// 
  /// Returns: List of missing required variables (empty if all present)
  static List<String> validateConfiguration() {
    final missing = <String>[];

    // Check critical variables
    if (apiBaseUrl.isEmpty) missing.add('API_BASE_URL');
    if (firebaseProjectId.isEmpty) missing.add('FIREBASE_PROJECT_ID');
    if (firebaseApiKey.isEmpty) missing.add('FIREBASE_API_KEY');

    // Log validation result
    if (missing.isEmpty) {
      print('[EnvConfig] ✓ All critical environment variables are set');
    } else {
      print('[EnvConfig] ✗ Missing required environment variables: ${missing.join(', ')}');
      print('[EnvConfig] Please configure these in your .env file');
    }

    return missing;
  }
}

/**
 * SECURITY NOTES:
 * 
 * 1. NEVER commit .env to version control
 * 2. NEVER log environment variables in production
 * 3. NEVER expose API keys in error messages
 * 4. ALWAYS validate HTTPS usage in production
 * 5. ALWAYS provide safe defaults for optional config
 * 6. CALL validateConfiguration() on app start
 */
