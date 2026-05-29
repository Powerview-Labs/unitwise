/// Global app configuration for UnitWise
/// 
/// This file contains feature flags, constants, and configuration values
/// used throughout the Appliance Estimator module.
/// 
/// SECURITY NOTE: No secrets or API keys should be stored here.
/// Use environment variables for sensitive data.
class AppConfig {
  // Prevent instantiation
  AppConfig._();
  
  // ========================================================================
  // ENVIRONMENT CONFIGURATION
  // ========================================================================
  
  /// Is the app running in test mode?
  /// When true: verbose logging, emulator backend, no SMS/notifications
  static const bool isTestMode = true;  // Match Module 1 configuration
  
  /// Use Firebase emulator for local development?
  static const bool useEmulator = true;
  
  // ========================================================================
  // FEATURE FLAGS
  // ========================================================================
  
  /// Enable analytics tracking (passive, non-blocking)
  /// Default: false (disabled for MVP)
  static const bool enableAnalytics = false;
  
  /// Enable optional cloud functions for band lookup
  /// Default: false (use Firestore directly for MVP)
  static const bool enableCloudFunctions = false;
  
  /// Enable accessibility features
  static const bool enableAccessibility = true;
  
  // ========================================================================
  // STORAGE CONFIGURATION
  // ========================================================================
  
  /// Key for encrypted local storage (flutter_secure_storage)
  static const String localStorageKey = 'appliance_estimator_v1';
  
  /// How many days to keep local drafts before expiring
  static const int draftCacheDays = 7;
  
  /// Firestore collection path for appliance estimator data
  /// Format: users/{uid}/appliance_estimator/current
  static const String firestoreCollection = 'appliance_estimator';
  static const String firestoreDocument = 'current';
  
  // ========================================================================
  // VALIDATION LIMITS
  // ========================================================================
  
  /// Maximum wattage before showing warning (not blocking)
  static const int maxWattage = 4000;
  
  /// Maximum hours per day
  static const int maxHours = 24;
  
  /// Minimum quantity per appliance
  static const int minQuantity = 1;
  
  /// Maximum quantity per appliance (warning threshold)
  static const int maxQuantity = 50;
  
  /// Maximum appliance name length
  static const int maxNameLength = 50;
  
  // ========================================================================
  // CALCULATION DEFAULTS
  // ========================================================================
  
  /// Default band supply hours if Module 2 data is missing
  /// CRITICAL: This is a SAFE FALLBACK, not a source of truth
  /// Actual band hours should come from users/{uid}/profile (Module 2)
  static const int bandHoursFallback = 12;
  
  /// Default unit rate (₦ per kWh) if Module 2 data is missing
  /// Based on average Nigerian DisCo rates (Band C)
  static const double defaultUnitRate = 69.0;
  
  // ========================================================================
  // PRECISION & DISPLAY
  // ========================================================================
  
  /// Decimal places for internal calculations (high precision)
  static const int decimalPlacesInternal = 4;
  
  /// Decimal places for UI display (user-friendly)
  static const int decimalPlacesDisplay = 1;
  
  // ========================================================================
  // POWER SAVER TIP THRESHOLDS
  // ========================================================================
  
  /// Wattage threshold for high-consumption candidate (watts)
  static const int highConsumptionWattage = 500;
  
  /// Daily units threshold for high-consumption candidate
  static const double highConsumptionUnits = 2.5;
  
  /// Hours per day threshold for high-consumption candidate
  static const int highConsumptionHours = 8;
  
  /// Maximum number of tips to show at once
  static const int maxTipsToShow = 3;
  
  // ========================================================================
  // UI CONFIGURATION
  // ========================================================================
  
  /// Minimum tap target size for accessibility (pixels)
  static const double minTapTargetSize = 44.0;
  
  /// Debounce delay for autosave (milliseconds)
  static const int autosaveDebounceMs = 2000;
  
  /// Toast/SnackBar duration (seconds)
  static const int toastDurationSeconds = 3;
  
  // ========================================================================
  // ANALYTICS CONFIGURATION (when enabled)
  // ========================================================================
  
  /// Analytics events for Appliance Estimator
  /// NOTE: These are passive and optional - see AnalyticsService
  static const String analyticsEventEstimatorStarted = 'appliance_estimator_started';
  static const String analyticsEventEstimatorCompleted = 'appliance_estimator_completed';
  static const String analyticsEventEstimatorSkipped = 'appliance_estimator_skipped';
  static const String analyticsEventApplianceAdded = 'appliance_added';
  static const String analyticsEventApplianceEdited = 'appliance_edited';
  static const String analyticsEventTipViewed = 'power_saver_tip_viewed';
  
  // ========================================================================
  // HELPER METHODS
  // ========================================================================
  
  /// Get descriptive environment name for debugging
  static String get environmentName {
    if (isTestMode) return 'TEST';
    if (useEmulator) return 'EMULATOR';
    return 'PRODUCTION';
  }
  
  /// Check if running in development mode
  static bool get isDevelopment => isTestMode || useEmulator;
  
  /// Get Firestore path for user's estimator document
  static String getEstimatorPath(String userId) {
    return 'users/$userId/$firestoreCollection/$firestoreDocument';
  }
}
