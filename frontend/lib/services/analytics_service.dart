import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

/// Abstract analytics service interface
/// 
/// CRITICAL: Analytics is PASSIVE, OPTIONAL, and NON-BLOCKING.
/// - Must NEVER affect estimator calculations
/// - Must NEVER affect UI behavior
/// - Must NEVER block saving
/// - If analytics fails, estimator continues normally
/// 
/// This is injectable with a no-op default implementation.
abstract class AnalyticsService {
  /// Log an analytics event
  /// 
  /// Parameters are optional and should only contain:
  /// - Anonymized/bucketed data
  /// - No PII (exact wattage, hours, token amounts)
  /// - Count-based metrics only
  void logEvent(String name, {Map<String, dynamic>? params});
  
  /// Log a screen view
  void logScreenView(String screenName);
}

/// No-op implementation (safe default)
/// 
/// This does nothing - analytics is disabled.
/// Use this for MVP or when analytics is not configured.
class NoOpAnalyticsService implements AnalyticsService {
  @override
  void logEvent(String name, {Map<String, dynamic>? params}) {
    // Do nothing - analytics disabled
    if (AppConfig.isTestMode) {
      debugPrint('📊 Analytics (no-op): $name ${params ?? ''}');
    }
  }
  
  @override
  void logScreenView(String screenName) {
    // Do nothing - analytics disabled
    if (AppConfig.isTestMode) {
      debugPrint('📊 Screen View (no-op): $screenName');
    }
  }
}

/// Firebase Analytics implementation (future)
/// 
/// Uncomment and implement when Firebase Analytics is ready.
/// 
/// ```dart
/// class FirebaseAnalyticsService implements AnalyticsService {
///   final FirebaseAnalytics _analytics;
///   
///   FirebaseAnalyticsService(this._analytics);
///   
///   @override
///   void logEvent(String name, {Map<String, dynamic>? params}) {
///     try {
///       _analytics.logEvent(name: name, parameters: params);
///     } catch (e) {
///       // Silently ignore - analytics failure must not break app
///       if (AppConfig.isTestMode) {
///         debugPrint('Analytics error: $e');
///       }
///     }
///   }
///   
///   @override
///   void logScreenView(String screenName) {
///     try {
///       _analytics.logScreenView(screenName: screenName);
///     } catch (e) {
///       // Silently ignore
///       if (AppConfig.isTestMode) {
///         debugPrint('Analytics error: $e');
///       }
///     }
///   }
/// }
/// ```

/// Helper class for analytics event tracking
/// 
/// Usage example in estimator:
/// ```dart
/// // After successful save (non-blocking, fire-and-forget)
/// try {
///   AnalyticsHelper.logEstimatorCompleted(
///     analytics: _analytics,
///     applianceCount: appliances.length,
///     dailyBurn: dailyBurnEstimate,
///   );
/// } catch (_) {
///   // Silently ignore analytics failure
/// }
/// ```
class AnalyticsHelper {
  // Prevent instantiation
  AnalyticsHelper._();
  
  /// Log estimator started event
  static void logEstimatorStarted(AnalyticsService analytics) {
    try {
      analytics.logEvent(AppConfig.analyticsEventEstimatorStarted);
    } catch (_) {
      // Silently ignore
    }
  }
  
  /// Log estimator completed event
  /// 
  /// Parameters are anonymized/bucketed:
  /// - appliance_count: integer (not specific list)
  /// - burn_bucket: "0-10", "10-20", "20-30", "30+" (not exact value)
  static void logEstimatorCompleted({
    required AnalyticsService analytics,
    required int applianceCount,
    required double dailyBurn,
  }) {
    try {
      analytics.logEvent(
        AppConfig.analyticsEventEstimatorCompleted,
        params: {
          'appliance_count': applianceCount,
          'burn_bucket': _getBurnBucket(dailyBurn),
        },
      );
    } catch (_) {
      // Silently ignore
    }
  }
  
  /// Log estimator skipped event
  static void logEstimatorSkipped(AnalyticsService analytics) {
    try {
      analytics.logEvent(AppConfig.analyticsEventEstimatorSkipped);
    } catch (_) {
      // Silently ignore
    }
  }
  
  /// Log appliance added event
  static void logApplianceAdded({
    required AnalyticsService analytics,
    required String category,
    required bool isCustom,
  }) {
    try {
      analytics.logEvent(
        AppConfig.analyticsEventApplianceAdded,
        params: {
          'category': category,
          'is_custom': isCustom,
        },
      );
    } catch (_) {
      // Silently ignore
    }
  }
  
  /// Log tip viewed event
  static void logTipViewed({
    required AnalyticsService analytics,
    required String tipType,
  }) {
    try {
      analytics.logEvent(
        AppConfig.analyticsEventTipViewed,
        params: {
          'tip_type': tipType,
        },
      );
    } catch (_) {
      // Silently ignore
    }
  }
  
  /// Get daily burn bucket for analytics (anonymized)
  /// 
  /// Examples: "0-10", "10-20", "20-30", "30+"
  static String _getBurnBucket(double dailyBurn) {
    if (dailyBurn < 10) return '0-10';
    if (dailyBurn < 20) return '10-20';
    if (dailyBurn < 30) return '20-30';
    return '30+';
  }
}
