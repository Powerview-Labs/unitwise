// 📄 File: lib/features/settings/models/settings_model.dart
// Phase 1: Foundation - Settings Data Model
// Security: All fields validated, no sensitive data exposed

import 'package:cloud_firestore/cloud_firestore.dart';

/// User Settings Model
/// 
/// Represents all user-configurable preferences and system settings.
/// 
/// SECURITY NOTES:
/// - All inputs validated before saving
/// - No sensitive credentials stored here
/// - Firestore rules enforce user can only read/write their own settings
/// 
/// CRITICAL PRINCIPLES:
/// - Settings NEVER rewrite history
/// - Settings affect FUTURE calculations only
/// - Band changes trigger forward-only recalculation
class UserSettings {
  // ========== LOCATION & BAND (High Impact) ==========
  /// DisCo name (e.g., "Ikeja Electric", "Eko Electric")
  /// VALIDATION: Must be one of the 11 valid Nigerian DisCos
  final String disco;

  /// Band classification (A, B, C, D, or E)
  /// VALIDATION: Must be A-E uppercase
  /// IMPACT: Changes trigger recalculation in Estimator, Dashboard, Budget Planner
  final String band;

  /// Band supply hours (derived from band)
  /// VALIDATION: Must be 4, 8, 12, 16, or 20 hours
  /// Band A = 20h, B = 16h, C = 12h, D = 8h, E = 4h
  final int bandSupplyHours;

  /// Timestamp of last band change
  /// Used for migration and audit logging
  final DateTime? bandChangedAt;

  // ========== METER INFO (Medium Impact) ==========
  /// Prepaid meter number
  /// VALIDATION: Trimmed, alphanumeric + hyphens only, max 50 chars
  /// Optional but useful for future automation
  final String meterNumber;

  // ========== ALERTS & THRESHOLDS (Medium Impact) ==========
  /// Low unit alert threshold (in kWh units)
  /// VALIDATION: 5-100 units
  /// DEFAULT: 10.0 units
  final double lowUnitThreshold;

  /// Enable/disable low unit alerts
  final bool lowUnitAlertsEnabled;

  /// Enable/disable critical alerts (< 1 day remaining)
  final bool criticalAlertsEnabled;

  // ========== BEHAVIORAL PREFERENCES ==========
  /// Outage mode ("No Light" toggle)
  /// When true, Virtual Burn Engine pauses
  final bool outageMode;

  /// Timestamp when outage mode was enabled
  /// Used for "still no light?" reminders
  final DateTime? outageModeEnabledAt;

  // ========== NOTIFICATIONS (Low Impact) ==========
  /// Master notification toggle
  final bool notificationsEnabled;

  /// Enable/disable behavioral reminders
  /// (e.g., "Estimator not updated in 30 days")
  final bool behavioralRemindersEnabled;

  // ========== UI PREFERENCES (No Logic Impact) ==========
  /// Theme preference: 'light', 'dark', or 'system'
  /// VALIDATION: Must be one of these three values
  final String theme;

  /// Language code (ISO 639-1)
  /// MVP: Only 'en' supported
  /// FUTURE: 'yo', 'ig', 'ha', 'pcm' (Pidgin)
  final String language;

  // ========== METADATA ==========
  final DateTime createdAt;
  final DateTime updatedAt;

  UserSettings({
    required this.disco,
    required this.band,
    required this.bandSupplyHours,
    this.bandChangedAt,
    this.meterNumber = '',
    this.lowUnitThreshold = 10.0,
    this.lowUnitAlertsEnabled = true,
    this.criticalAlertsEnabled = true,
    this.outageMode = false,
    this.outageModeEnabledAt,
    this.notificationsEnabled = true,
    this.behavioralRemindersEnabled = true,
    this.theme = 'system',
    this.language = 'en',
    required this.createdAt,
    required this.updatedAt,
  });

  // ========== FACTORY CONSTRUCTORS ==========

  /// Create settings from Firestore document
  factory UserSettings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserSettings(
      disco: data['disco'] as String? ?? 'Unknown DisCo',
      band: data['band'] as String? ?? 'C',
      bandSupplyHours: data['bandSupplyHours'] as int? ?? 12,
      bandChangedAt: data['bandChangedAt'] != null
          ? (data['bandChangedAt'] as Timestamp).toDate()
          : null,
      meterNumber: data['meterNumber'] as String? ?? '',
      lowUnitThreshold: (data['lowUnitThreshold'] as num?)?.toDouble() ?? 10.0,
      lowUnitAlertsEnabled: data['lowUnitAlertsEnabled'] as bool? ?? true,
      criticalAlertsEnabled: data['criticalAlertsEnabled'] as bool? ?? true,
      outageMode: data['outageMode'] as bool? ?? false,
      outageModeEnabledAt: data['outageModeEnabledAt'] != null
          ? (data['outageModeEnabledAt'] as Timestamp).toDate()
          : null,
      notificationsEnabled: data['notificationsEnabled'] as bool? ?? true,
      behavioralRemindersEnabled:
          data['behavioralRemindersEnabled'] as bool? ?? true,
      theme: data['theme'] as String? ?? 'system',
      language: data['language'] as String? ?? 'en',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Create default settings for new user
  /// Used during onboarding after Location Setup completes
  factory UserSettings.createDefault({
    required String disco,
    required String band,
    String? meterNumber,
  }) {
    final now = DateTime.now();
    final supplyHours = _getBandSupplyHours(band);

    return UserSettings(
      disco: disco,
      band: band,
      bandSupplyHours: supplyHours,
      meterNumber: meterNumber ?? '',
      createdAt: now,
      updatedAt: now,
    );
  }

  // ========== CONVERSION METHODS ==========

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'disco': disco,
      'band': band,
      'bandSupplyHours': bandSupplyHours,
      'bandChangedAt': bandChangedAt != null
          ? Timestamp.fromDate(bandChangedAt!)
          : null,
      'meterNumber': meterNumber,
      'lowUnitThreshold': lowUnitThreshold,
      'lowUnitAlertsEnabled': lowUnitAlertsEnabled,
      'criticalAlertsEnabled': criticalAlertsEnabled,
      'outageMode': outageMode,
      'outageModeEnabledAt': outageModeEnabledAt != null
          ? Timestamp.fromDate(outageModeEnabledAt!)
          : null,
      'notificationsEnabled': notificationsEnabled,
      'behavioralRemindersEnabled': behavioralRemindersEnabled,
      'theme': theme,
      'language': language,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // ========== COPY WITH (Immutable Updates) ==========

  UserSettings copyWith({
    String? disco,
    String? band,
    int? bandSupplyHours,
    DateTime? bandChangedAt,
    String? meterNumber,
    double? lowUnitThreshold,
    bool? lowUnitAlertsEnabled,
    bool? criticalAlertsEnabled,
    bool? outageMode,
    DateTime? outageModeEnabledAt,
    bool? notificationsEnabled,
    bool? behavioralRemindersEnabled,
    String? theme,
    String? language,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSettings(
      disco: disco ?? this.disco,
      band: band ?? this.band,
      bandSupplyHours: bandSupplyHours ?? this.bandSupplyHours,
      bandChangedAt: bandChangedAt ?? this.bandChangedAt,
      meterNumber: meterNumber ?? this.meterNumber,
      lowUnitThreshold: lowUnitThreshold ?? this.lowUnitThreshold,
      lowUnitAlertsEnabled: lowUnitAlertsEnabled ?? this.lowUnitAlertsEnabled,
      criticalAlertsEnabled:
          criticalAlertsEnabled ?? this.criticalAlertsEnabled,
      outageMode: outageMode ?? this.outageMode,
      outageModeEnabledAt: outageModeEnabledAt ?? this.outageModeEnabledAt,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      behavioralRemindersEnabled:
          behavioralRemindersEnabled ?? this.behavioralRemindersEnabled,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ========== HELPER METHODS ==========

  /// Get supply hours for a given band
  static int _getBandSupplyHours(String band) {
    const bandHours = {
      'A': 20,
      'B': 16,
      'C': 12,
      'D': 8,
      'E': 4,
    };
    return bandHours[band.toUpperCase()] ?? 12; // Default to C
  }

  /// Check if settings are complete (all required fields set)
  bool get isComplete {
    return disco.isNotEmpty && band.isNotEmpty && meterNumber.isNotEmpty;
  }

  /// Get outage duration in hours
  /// Returns null if outage mode is not active
  int? get outageDurationHours {
    if (!outageMode || outageModeEnabledAt == null) return null;
    return DateTime.now().difference(outageModeEnabledAt!).inHours;
  }

  @override
  String toString() {
    return 'UserSettings(disco: $disco, band: $band, meterNumber: $meterNumber, outageMode: $outageMode)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserSettings &&
        other.disco == disco &&
        other.band == band &&
        other.bandSupplyHours == bandSupplyHours &&
        other.meterNumber == meterNumber &&
        other.lowUnitThreshold == lowUnitThreshold &&
        other.outageMode == outageMode &&
        other.theme == theme;
  }

  @override
  int get hashCode {
    return Object.hash(
      disco,
      band,
      bandSupplyHours,
      meterNumber,
      lowUnitThreshold,
      outageMode,
      theme,
    );
  }
}
