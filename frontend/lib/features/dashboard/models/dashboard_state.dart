import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Core dashboard state model
/// This is the single source of truth for electricity tracking
///
/// SECURITY:
/// - All numeric fields validated for NaN/Infinity/negative values
/// - Timestamps validated to prevent future dates
/// - Firestore serialization sanitized
///
/// ✅ CRITICAL FIXES APPLIED:
/// - Added outageStartedAt field for accurate outage tracking
/// - Added toJson/fromJson for local caching support
class DashboardState {
  /// Current estimated unit balance (always >= 0)
  final double estimatedUnits;

  /// Daily burn rate from Appliance Estimator (always >= 0)
  final double dailyBurnRate;

  /// Estimated days remaining (null if burn rate is 0)
  final double? daysRemaining;

  /// When was the last token logged
  final DateTime? lastTokenLog;

  /// When was this state last calculated
  final DateTime lastCalculatedAt;

  /// Is outage mode currently active
  final bool outageModeActive;

  /// Total outage days accumulated
  final int outageDays;

  /// ✅ CRITICAL FIX #2: When current outage started (null if no active outage)
  final DateTime? outageStartedAt;

  /// Is manual override currently active
  final bool manualOverride;

  /// Manual unit value (only if override active)
  final double? manualUnits;

  /// When was manual override set
  final DateTime? manualOverrideTimestamp;

  /// Alert state
  final AlertState alerts;

  /// User readiness flags
  final bool hasTokenLogged;
  final bool hasEstimatorCompleted;

  const DashboardState({
    required this.estimatedUnits,
    required this.dailyBurnRate,
    this.daysRemaining,
    this.lastTokenLog,
    required this.lastCalculatedAt,
    this.outageModeActive = false,
    this.outageDays = 0,
    this.outageStartedAt,
    this.manualOverride = false,
    this.manualUnits,
    this.manualOverrideTimestamp,
    required this.alerts,
    this.hasTokenLogged = false,
    this.hasEstimatorCompleted = false,
  });

  /// Factory: Empty state for first-time users
  /// Used when no data exists in Firestore or cache
  factory DashboardState.empty() {
    return DashboardState(
      estimatedUnits: 0.0,
      dailyBurnRate: 0.0,
      daysRemaining: null,
      lastCalculatedAt: DateTime.now(),
      alerts: AlertState.none(),
      hasTokenLogged: false,
      hasEstimatorCompleted: false,
    );
  }

  /// Factory: From Firestore document
  /// SECURITY: All inputs validated before assignment
  factory DashboardState.fromFirestore(Map<String, dynamic> data) {
    try {
      // SECURITY: Validate and sanitize numeric inputs
      final units = _sanitizeDouble(
        (data['estimated_units'] as num?)?.toDouble(),
        defaultValue: 0.0,
        allowNegative: false,
      );

      final burnRate = _sanitizeDouble(
        (data['daily_burn_rate'] as num?)?.toDouble(),
        defaultValue: 0.0,
        allowNegative: false,
      );

      final daysRemaining = _sanitizeDouble(
        (data['days_remaining'] as num?)?.toDouble(),
        defaultValue: null,
        allowNegative: false,
      );

      final manualUnits = _sanitizeDouble(
        (data['manual_units'] as num?)?.toDouble(),
        defaultValue: null,
        allowNegative: false,
      );

      // Parse timestamps
      final lastTokenLog = (data['last_token_log'] as Timestamp?)?.toDate();
      final lastCalculatedAt = (data['last_calculated_at'] as Timestamp?)?.toDate()
          ?? DateTime.now();
      final manualOverrideTimestamp = (data['manual_override_timestamp'] as Timestamp?)?.toDate();
      final outageStartedAt = (data['outage_started_at'] as Timestamp?)?.toDate();

      // Validate timestamps (cannot be in the future)
      final now = DateTime.now();
      final validLastCalc = lastCalculatedAt.isAfter(now) ? now : lastCalculatedAt;
      final validTokenLog = lastTokenLog != null && lastTokenLog.isAfter(now)
          ? null
          : lastTokenLog;

      return DashboardState(
        estimatedUnits: units ?? 0.0,
        dailyBurnRate: burnRate ?? 0.0,
        daysRemaining: daysRemaining,
        lastTokenLog: validTokenLog,
        lastCalculatedAt: validLastCalc,
        outageModeActive: data['outage_mode_active'] as bool? ?? false,
        outageDays: (data['outage_days'] as int? ?? 0).clamp(0, 365), // Max 1 year
        outageStartedAt: outageStartedAt,
        manualOverride: data['manual_override'] as bool? ?? false,
        manualUnits: manualUnits,
        manualOverrideTimestamp: manualOverrideTimestamp,
        alerts: AlertState.fromMap(data['alerts'] as Map<String, dynamic>? ?? {}),
        hasTokenLogged: data['has_token_logged'] as bool? ?? false,
        hasEstimatorCompleted: data['has_estimator_completed'] as bool? ?? false,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DashboardState] Error parsing Firestore data: $e');
      }
      // Return safe empty state on error
      return DashboardState.empty();
    }
  }

  /// Convert to Firestore-safe map
  Map<String, dynamic> toFirestore() {
    return {
      'estimated_units': estimatedUnits,
      'daily_burn_rate': dailyBurnRate,
      'days_remaining': daysRemaining,
      'last_token_log': lastTokenLog != null
          ? Timestamp.fromDate(lastTokenLog!)
          : null,
      'last_calculated_at': Timestamp.fromDate(lastCalculatedAt),
      'outage_mode_active': outageModeActive,
      'outage_days': outageDays,
      'outage_started_at': outageStartedAt != null
          ? Timestamp.fromDate(outageStartedAt!)
          : null,
      'manual_override': manualOverride,
      'manual_units': manualUnits,
      'manual_override_timestamp': manualOverrideTimestamp != null
          ? Timestamp.fromDate(manualOverrideTimestamp!)
          : null,
      'alerts': alerts.toMap(),
      'has_token_logged': hasTokenLogged,
      'has_estimator_completed': hasEstimatorCompleted,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  /// ✅ CRITICAL FIX #3: Serialize to JSON for local cache
  Map<String, dynamic> toJson() {
    return {
      'estimated_units': estimatedUnits,
      'daily_burn_rate': dailyBurnRate,
      'days_remaining': daysRemaining,
      'last_token_log': lastTokenLog?.toIso8601String(),
      'last_calculated_at': lastCalculatedAt.toIso8601String(),
      'outage_mode_active': outageModeActive,
      'outage_days': outageDays,
      'outage_started_at': outageStartedAt?.toIso8601String(),
      'manual_override': manualOverride,
      'manual_units': manualUnits,
      'manual_override_timestamp': manualOverrideTimestamp?.toIso8601String(),
      'alerts': alerts.toMap(),
      'has_token_logged': hasTokenLogged,
      'has_estimator_completed': hasEstimatorCompleted,
    };
  }

  /// ✅ CRITICAL FIX #3: Deserialize from JSON cache
  factory DashboardState.fromJson(Map<String, dynamic> json) {
    try {
      return DashboardState(
        estimatedUnits: (json['estimated_units'] as num?)?.toDouble() ?? 0.0,
        dailyBurnRate: (json['daily_burn_rate'] as num?)?.toDouble() ?? 0.0,
        daysRemaining: (json['days_remaining'] as num?)?.toDouble(),
        lastTokenLog: json['last_token_log'] != null
            ? DateTime.parse(json['last_token_log'] as String)
            : null,
        lastCalculatedAt: DateTime.parse(
          json['last_calculated_at'] as String? ?? DateTime.now().toIso8601String(),
        ),
        outageModeActive: json['outage_mode_active'] as bool? ?? false,
        outageDays: json['outage_days'] as int? ?? 0,
        outageStartedAt: json['outage_started_at'] != null
            ? DateTime.parse(json['outage_started_at'] as String)
            : null,
        manualOverride: json['manual_override'] as bool? ?? false,
        manualUnits: (json['manual_units'] as num?)?.toDouble(),
        manualOverrideTimestamp: json['manual_override_timestamp'] != null
            ? DateTime.parse(json['manual_override_timestamp'] as String)
            : null,
        alerts: AlertState.fromMap(
          json['alerts'] as Map<String, dynamic>? ?? {},
        ),
        hasTokenLogged: json['has_token_logged'] as bool? ?? false,
        hasEstimatorCompleted: json['has_estimator_completed'] as bool? ?? false,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DashboardState] Error parsing JSON: $e');
      }
      return DashboardState.empty();
    }
  }

  /// Get current user readiness state for UI behavior
  UserReadinessState get userState {
    if (hasTokenLogged && hasEstimatorCompleted) {
      return UserReadinessState.ready;
    } else if (!hasEstimatorCompleted) {
      return UserReadinessState.estimatorMissing;
    } else if (!hasTokenLogged) {
      return UserReadinessState.tokenMissing;
    } else {
      return UserReadinessState.firstTime;
    }
  }

  /// Get unit color state based on thresholds
  UnitColorState get unitColorState {
    if (estimatedUnits > 30) return UnitColorState.safe;
    if (estimatedUnits >= 10) return UnitColorState.moderate;
    return UnitColorState.danger;
  }

  /// Check if dashboard can show forecasts
  bool get canShowForecasts => hasEstimatorCompleted && hasTokenLogged;

  /// Immutable copy with updated fields
  DashboardState copyWith({
    double? estimatedUnits,
    double? dailyBurnRate,
    double? daysRemaining,
    DateTime? lastTokenLog,
    DateTime? lastCalculatedAt,
    bool? outageModeActive,
    int? outageDays,
    DateTime? outageStartedAt,
    bool? manualOverride,
    double? manualUnits,
    DateTime? manualOverrideTimestamp,
    AlertState? alerts,
    bool? hasTokenLogged,
    bool? hasEstimatorCompleted,
  }) {
    return DashboardState(
      estimatedUnits: estimatedUnits ?? this.estimatedUnits,
      dailyBurnRate: dailyBurnRate ?? this.dailyBurnRate,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      lastTokenLog: lastTokenLog ?? this.lastTokenLog,
      lastCalculatedAt: lastCalculatedAt ?? this.lastCalculatedAt,
      outageModeActive: outageModeActive ?? this.outageModeActive,
      outageDays: outageDays ?? this.outageDays,
      outageStartedAt: outageStartedAt ?? this.outageStartedAt,
      manualOverride: manualOverride ?? this.manualOverride,
      manualUnits: manualUnits ?? this.manualUnits,
      manualOverrideTimestamp: manualOverrideTimestamp ?? this.manualOverrideTimestamp,
      alerts: alerts ?? this.alerts,
      hasTokenLogged: hasTokenLogged ?? this.hasTokenLogged,
      hasEstimatorCompleted: hasEstimatorCompleted ?? this.hasEstimatorCompleted,
    );
  }

  /// SECURITY: Sanitize double values
  /// Prevents NaN, Infinity, and optionally negative values
  static double? _sanitizeDouble(
    double? value, {
    required double? defaultValue,
    required bool allowNegative,
  }) {
    if (value == null) return defaultValue;
    if (value.isNaN || value.isInfinite) return defaultValue;
    if (!allowNegative && value < 0) return defaultValue;
    return value;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardState &&
          runtimeType == other.runtimeType &&
          estimatedUnits == other.estimatedUnits &&
          dailyBurnRate == other.dailyBurnRate &&
          outageModeActive == other.outageModeActive &&
          manualOverride == other.manualOverride;

  @override
  int get hashCode =>
      estimatedUnits.hashCode ^
      dailyBurnRate.hashCode ^
      outageModeActive.hashCode ^
      manualOverride.hashCode;
}

/// Alert state model
class AlertState {
  final bool lowUnits;
  final bool critical;
  final List<String> suggestions;

  const AlertState({
    required this.lowUnits,
    required this.critical,
    required this.suggestions,
  });

  factory AlertState.none() {
    return const AlertState(
      lowUnits: false,
      critical: false,
      suggestions: [],
    );
  }

  factory AlertState.fromMap(Map<String, dynamic> data) {
    try {
      return AlertState(
        lowUnits: data['low_units'] as bool? ?? false,
        critical: data['critical'] as bool? ?? false,
        suggestions: (data['suggestions'] as List?)?.cast<String>() ?? [],
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AlertState] Error parsing: $e');
      }
      return AlertState.none();
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'low_units': lowUnits,
      'critical': critical,
      'suggestions': suggestions,
    };
  }

  bool get hasAlerts => lowUnits || critical;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlertState &&
          runtimeType == other.runtimeType &&
          lowUnits == other.lowUnits &&
          critical == other.critical;

  @override
  int get hashCode => lowUnits.hashCode ^ critical.hashCode;
}

/// User readiness state enum
/// Determines what UI elements should be shown
enum UserReadinessState {
  /// Token + Estimator complete - full dashboard
  ready,

  /// Token exists but no estimator - limited dashboard
  estimatorMissing,

  /// No token logged - prompt to log token
  tokenMissing,

  /// Brand new user - safe initialization
  firstTime,
}

/// Unit color state enum
/// Determines color coding for unit display
enum UnitColorState {
  /// > 30 units (Blue)
  safe,

  /// 10-30 units (Yellow)
  moderate,

  /// < 10 units (Red)
  danger,
}